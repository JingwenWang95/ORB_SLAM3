import trimesh
import numpy as np
import os
import pyglet
pyglet.options['headless'] = True
assert(pyglet.window.Window == pyglet.window.headless.HeadlessWindow)
import torch
from pytorch3d.transforms import quaternion_to_matrix

pose_dict = {}

with open(os.path.join(os.path.dirname(__file__), "build/CameraTrajectory.txt")) as f:
    for line in f:
        if line.startswith('#'):
            continue
        t, tx, ty, tz, qx, qy, qz, qw = np.array(line.rstrip().split(' ')).astype(float)
        rotmat = quaternion_to_matrix(torch.tensor([qw, qx, qy, qz])).numpy()

        pose = np.concatenate([np.concatenate([rotmat, np.array([[tx], [ty], [tz]])], axis=1),
                               np.array([[0., 0., 0., 1.]])])

        pose_dict[str(t)] = pose

kp_dir = os.path.join(os.path.dirname(__file__), 'per_frame_keypoints')
files = [f for f in os.listdir(kp_dir) if os.path.isfile(os.path.join(kp_dir, f))]

out_dir = os.path.join(os.path.dirname(__file__), 'per_frame_keypoints_vis/')
if not os.path.exists(out_dir):
    os.makedirs(out_dir)

for i, file in enumerate(files):

    timestamp = file.replace('.npy', '')

    if not (timestamp in pose_dict.keys()):
        continue

    marker = trimesh.creation.camera_marker(trimesh.scene.Camera(focal=(500,400), resolution=(640,480)), marker_height=.3)
    marker[1].colors = np.ones((5, 4), dtype=np.uint8) * [[0, 0, 255, 255]]
    marker[1].apply_transform(pose_dict[timestamp])

    points = np.load(os.path.join(kp_dir, file))
    pc = trimesh.points.PointCloud(points)
    camera = trimesh.scene.Camera(name='camera', resolution=[640, 480], fov=[90, 60], z_near=0.01, z_far=1000.0)
    scene = trimesh.Scene([pc, marker[1]], camera=camera)
    scene.set_camera(distance=10., angles=[0., 0., 0.], center=[0.,0.,0.])
    png = scene.save_image(resolution=(640, 480))
    png_file = os.path.join(os.path.dirname(__file__), 'per_frame_keypoints_vis/', timestamp + '.png')

    with open(png_file, 'wb') as f:
        f.write(png)
        f.close()

# for GIF generation use:
# convert -delay 3 -quality 85% -loop 0 per_frame_keypoints_vis/*.png seq.gif