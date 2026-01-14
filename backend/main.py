"""Face swap GIF processing backend"""
import os
import tempfile
import numpy as np
import concurrent.futures
from concurrent.futures import ThreadPoolExecutor

# Set matplotlib to use non-GUI backend before importing any visualization libraries
import matplotlib
matplotlib.use('Agg')

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
import cv2
import insightface
import imageio
from PIL import Image
import asyncio
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Face Swap API")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Thread pool for parallel processing
executor = ThreadPoolExecutor(max_workers=4)

# Initialize InsightFace model - using glintr100 (faster) instead of buffalo_l
try:
    # Initialize the face analyzer and swapper
    face_analyzer = insightface.app.FaceAnalysis(
        name='buffalo_l',
        providers=['CPUExecutionProvider']
    )
    face_analyzer.prepare(ctx_id=0, det_size=(512, 512))
    
    # Download inswapper model with full download path
    face_swapper = insightface.model_zoo.get_model(
        'inswapper_128.onnx',
        download=True,
        download_zip=True,
        providers=['CPUExecutionProvider']
    )
    logger.info("InsightFace models loaded successfully")
except Exception as e:
    logger.error(f"Failed to load InsightFace models: {e}")
    face_analyzer = None
    face_swapper = None


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "models_loaded": face_analyzer is not None and face_swapper is not None
    }


def extract_face_embedding(image_path: str):
    """Extract face embedding from image with highest confidence"""
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError("Failed to load image")
    
    faces = face_analyzer.get(img)
    if not faces:
        raise ValueError("No face detected in image")
    
    # Use the face with highest detection confidence for most stable embedding
    face = max(faces, key=lambda f: f.det_score)
    logger.info(f"Extracted source face with confidence: {face.det_score}")
    return face


def swap_faces_in_frame(frame: np.ndarray, source_face, target_faces, source_face_index: int = 0) -> np.ndarray:
    """Swap source face into frame containing target faces with consistent identity.
    
    Args:
        frame: Frame to process
        source_face: Source face embedding (reference from Page 2)
        target_faces: List of detected target faces in the frame
        source_face_index: Index of source face for consistency
    
    Returns:
        Frame with swapped faces
    """
    if not target_faces:
        return frame
    
    result = frame.copy()
    
    # Swap all detected faces with the same source face to maintain identity consistency
    for target_face in target_faces:
        try:
            # Use consistent source face for all swaps to prevent drifting
            result = face_swapper.get(result, target_face, source_face)
        except Exception as e:
            logger.warning(f"Failed to swap face: {e}")
            continue
    
    return result


def process_frame(args):
    """Process a single frame - can be called in parallel.
    
    Ensures consistent identity (Page 2) across all frames by using the same source face embedding.
    """
    frame_idx, frame, source_face = args
    
    try:
        # Convert to BGR for face detection
        if frame.shape[2] == 4:  # RGBA
            frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGBA2BGR)
        else:
            frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
        
        # Detect faces in frame with consistent parameters for stability
        target_faces = face_analyzer.get(frame_bgr)
        
        # Swap faces with consistent source identity
        if target_faces:
            # Sort faces by position to ensure consistent order and prevent face drifting
            target_faces = sorted(target_faces, key=lambda f: (f.bbox[0], f.bbox[1]))
            swapped_frame = swap_faces_in_frame(frame_bgr, source_face, target_faces)
            # Convert back to RGB
            swapped_frame = cv2.cvtColor(swapped_frame, cv2.COLOR_BGR2RGB)
            return swapped_frame
        else:
            return frame[:, :, :3] if frame.shape[2] == 4 else frame
    except Exception as e:
        logger.warning(f"Error processing frame {frame_idx}: {e}")
        return frame[:, :, :3] if frame.shape[2] == 4 else frame


def process_gif_frames(gif_path: str, source_face_path: str) -> str:
    """Process GIF and swap faces in each frame while maintaining consistent identity.
    
    Uses Page 2 (uploaded reference face) as the locked identity across all frames.
    Prevents face drifting by using the same source face embedding throughout.
    Optimized to process every 2nd frame for faster processing.
    """
    try:
        # Extract source face from Page 2 (reference image) - this is the ONLY identity to use
        source_face = extract_face_embedding(source_face_path)
        logger.info(f"Source face (Page 2) locked with confidence: {source_face.det_score:.4f}")
        logger.info("This identity will be maintained consistently across all frames")
        
        # Read all GIF frames
        gif_reader = imageio.get_reader(gif_path)
        all_frames = list(gif_reader)
        
        logger.info(f"Total GIF frames: {len(all_frames)}")
        
        # Select every 2nd frame for processing (optimization)
        frames_to_process = all_frames[::2]  # Every 2nd frame
        frame_indices = list(range(0, len(all_frames), 2))  # Indices of frames being processed
        
        logger.info(f"Processing {len(frames_to_process)} frames (every 2nd frame) using identity-locked mode")
        logger.info(f"Reference identity from Page 2 will be used for all processed frames")
        
        # Process frames in parallel using thread pool
        with ThreadPoolExecutor(max_workers=4) as parallel_executor:
            frame_data = [(idx, frame, source_face) for idx, frame in enumerate(frames_to_process)]
            processed_frames = list(parallel_executor.map(process_frame, frame_data))
        
        logger.info(f"Successfully processed {len(processed_frames)} frames with consistent identity")
        
        # Reconstruct full GIF by duplicating processed frames to maintain animation smoothness
        # For every processed frame, keep the original next frame (unprocessed)
        full_output_frames = []
        processed_idx = 0
        for i in range(len(all_frames)):
            if i in frame_indices:
                full_output_frames.append(processed_frames[processed_idx])
                processed_idx += 1
            else:
                # Use the previous processed frame for in-between frames (maintains consistency)
                if processed_idx > 0:
                    full_output_frames.append(processed_frames[processed_idx - 1])
                else:
                    full_output_frames.append(all_frames[i])
        
        logger.info(f"Full output GIF has {len(full_output_frames)} frames")
        
        # Save processed GIF with optimized compression
        output_path = tempfile.mktemp(suffix='.gif')
        imageio.mimsave(output_path, full_output_frames, format='GIF', duration=100, loop=0, optimize=False)
        logger.info(f"GIF saved to {output_path}")
        
        return output_path
    
    except Exception as e:
        logger.error(f"Error processing GIF: {e}")
        raise


@app.post("/detect-faces")
async def detect_faces(face_image: UploadFile = File(...)):
    """
    Detect faces in an uploaded image and return bounding box coordinates
    
    Args:
        face_image: Image to detect faces in
    
    Returns:
        JSON with array of detected faces with bounding boxes and confidence scores
    """
    temp_file = None
    try:
        # Save uploaded file temporarily
        face_temp = tempfile.NamedTemporaryFile(delete=False, suffix='.png')
        temp_file = face_temp.name
        
        # Write face image
        face_content = await face_image.read()
        face_temp.write(face_content)
        face_temp.close()
        
        logger.info(f"Face detection image uploaded: {face_temp.name}")
        
        if face_analyzer is None:
            raise HTTPException(status_code=500, detail="Face analyzer not loaded")
        
        # Load image and detect faces
        img = cv2.imread(face_temp.name)
        if img is None:
            raise HTTPException(status_code=400, detail="Failed to load image")
        
        faces = face_analyzer.get(img)
        
        # Convert face data to response format
        detected_faces = []
        for idx, face in enumerate(faces):
            bbox = face.bbox.astype(int).tolist()  # [x1, y1, x2, y2]
            detected_faces.append({
                "index": idx,
                "bbox": {
                    "x": bbox[0],
                    "y": bbox[1],
                    "width": bbox[2] - bbox[0],
                    "height": bbox[3] - bbox[1]
                },
                "confidence": float(face.det_score)
            })
        
        logger.info(f"Detected {len(detected_faces)} face(s)")
        
        return {
            "faces": detected_faces,
            "count": len(detected_faces)
        }
    
    except Exception as e:
        logger.error(f"Error in detect_faces: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Cleanup temp file
        if temp_file and os.path.exists(temp_file):
            try:
                os.remove(temp_file)
            except Exception as e:
                logger.warning(f"Failed to cleanup {temp_file}: {e}")


@app.post("/swap-face")
async def swap_face(gif_file: UploadFile = File(...), face_image: UploadFile = File(...)):
    """
    Swap face in GIF with uploaded face image
    
    Args:
        gif_file: GIF file to process
        face_image: Image containing the face to swap in
    
    Returns:
        Processed GIF with swapped face
    """
    temp_files = []
    try:
        # Save uploaded files temporarily
        gif_temp = tempfile.NamedTemporaryFile(delete=False, suffix='.gif')
        face_temp = tempfile.NamedTemporaryFile(delete=False, suffix='.png')
        
        temp_files = [gif_temp.name, face_temp.name]
        
        # Write GIF
        gif_content = await gif_file.read()
        gif_temp.write(gif_content)
        gif_temp.close()
        
        # Write face image
        face_content = await face_image.read()
        face_temp.write(face_content)
        face_temp.close()
        
        logger.info(f"Files uploaded: GIF={gif_temp.name}, Face={face_temp.name}")
        
        if face_analyzer is None or face_swapper is None:
            raise HTTPException(status_code=500, detail="AI models not loaded")
        
        # Process GIF
        output_path = await asyncio.to_thread(
            process_gif_frames,
            gif_temp.name,
            face_temp.name
        )
        
        # Return as streaming response
        return FileResponse(
            output_path,
            media_type="image/gif",
            filename="swapped.gif"
        )
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error in swap_face: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Cleanup temp files
        for temp_file in temp_files:
            try:
                if os.path.exists(temp_file):
                    os.remove(temp_file)
            except Exception as e:
                logger.warning(f"Failed to cleanup {temp_file}: {e}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
