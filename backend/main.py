"""Face swap GIF processing backend"""
import os
import tempfile
import numpy as np

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

# Initialize InsightFace model
try:
    # Initialize the face analyzer and swapper
    # Use CPUExecutionProvider instead of CPUProvider (correct name for ONNX Runtime)
    face_analyzer = insightface.app.FaceAnalysis(
        name='buffalo_l',
        providers=['CPUExecutionProvider']
    )
    face_analyzer.prepare(ctx_id=0, det_size=(640, 640))
    
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
    """Extract face embedding from image"""
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError("Failed to load image")
    
    faces = face_analyzer.get(img)
    if not faces:
        raise ValueError("No face detected in image")
    
    # Use the largest face
    face = max(faces, key=lambda f: f.det_score)
    return face


def swap_faces_in_frame(frame: np.ndarray, source_face, target_faces) -> np.ndarray:
    """Swap source face into frame containing target faces"""
    if not target_faces:
        return frame
    
    result = frame.copy()
    
    for target_face in target_faces:
        try:
            result = face_swapper.get(result, target_face, source_face)
        except Exception as e:
            logger.warning(f"Failed to swap face: {e}")
            continue
    
    return result


def process_gif_frames(gif_path: str, source_face_path: str) -> str:
    """Process GIF and swap faces in each frame"""
    try:
        # Extract source face
        source_face = extract_face_embedding(source_face_path)
        logger.info("Source face extracted")
        
        # Read GIF frames
        gif_reader = imageio.get_reader(gif_path)
        frames = []
        
        logger.info(f"Processing GIF with {len(gif_reader)} frames")
        
        for frame_idx, frame in enumerate(gif_reader):
            # Convert to BGR for face detection
            if frame.shape[2] == 4:  # RGBA
                frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGBA2BGR)
            else:
                frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
            
            # Detect faces in frame
            target_faces = face_analyzer.get(frame_bgr)
            
            # Swap faces
            if target_faces:
                swapped_frame = swap_faces_in_frame(frame_bgr, source_face, target_faces)
                # Convert back to RGB
                swapped_frame = cv2.cvtColor(swapped_frame, cv2.COLOR_BGR2RGB)
                frames.append(swapped_frame)
                logger.info(f"Frame {frame_idx + 1}: {len(target_faces)} face(s) swapped")
            else:
                frames.append(frame[:, :, :3] if frame.shape[2] == 4 else frame)
                logger.info(f"Frame {frame_idx + 1}: No faces detected, keeping original")
        
        # Save processed GIF
        output_path = tempfile.mktemp(suffix='.gif')
        imageio.mimsave(output_path, frames, format='GIF', duration=100)
        logger.info(f"GIF saved to {output_path}")
        
        return output_path
    
    except Exception as e:
        logger.error(f"Error processing GIF: {e}")
        raise


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
