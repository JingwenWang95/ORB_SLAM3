#!/bin/bash -e
#
# This is a build script for ORB-SLAM3.
#
# Example:
#   ./build.sh
#
#   which will
#   1. Install some system dependencies
#   2. Install CUDA-11.3 under /usr/local
#   3. Create and build:
#   - ./Thirdparty/opencv
#   - ./Thirdparty/eigen
#   - ./Thirdparty/Pangolin
#   4. Build:
#   - ./Thirdparty/g2o
#   - ./Thirdparty/DBoW2

# Function that executes the clone command given as $1 iff repo does not exist yet. Otherwise pulls.
# Only works if repository path ends with '.git'
# Example: git_clone "git clone --branch 3.4.1 --depth=1 https://github.com/opencv/opencv.git"
function git_clone(){
  repo_dir=`basename "$1" .git`
  git -C "$repo_dir" pull 2> /dev/null || eval "$1"
}

source Thirdparty/bashcolors/bash_colors.sh
function highlight(){
  clr_magentab clr_bold clr_white "$1"
}

highlight "Installing system-wise packages ..."
sudo apt-get update > /dev/null 2>&1 &&
sudo apt-get install -y \
  libglew-dev \
  libgtk2.0-dev \
  pkg-config \
  libegl1-mesa-dev \
  libwayland-dev \
  libxkbcommon-dev \
  wayland-protocols

highlight "Installing OpenCV ..."
cd Thirdparty
git_clone "git clone --branch 3.4.1 --depth=1 https://github.com/opencv/opencv.git"
cd opencv
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_CUDA=OFF  \
    -DBUILD_DOCS=OFF  \
    -DBUILD_PACKAGE=OFF \
    -DBUILD_TESTS=OFF  \
    -DBUILD_PERF_TESTS=OFF  \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_opencv_calib3d=ON  \
    -DBUILD_opencv_cudaoptflow=OFF  \
    -DBUILD_opencv_dnn=OFF  \
    -DBUILD_opencv_dnn_BUILD_TORCH_IMPORTER=OFF  \
    -DBUILD_opencv_features2d=ON \
    -DBUILD_opencv_flann=ON \
    -DBUILD_opencv_java=ON  \
    -DBUILD_opencv_objdetect=ON  \
    -DBUILD_opencv_python2=OFF  \
    -DBUILD_opencv_python3=OFF  \
    -DBUILD_opencv_photo=ON \
    -DBUILD_opencv_stitching=ON  \
    -DBUILD_opencv_superres=ON  \
    -DBUILD_opencv_shape=ON  \
    -DBUILD_opencv_videostab=OFF \
    -DBUILD_PROTOBUF=OFF \
    -DWITH_1394=OFF  \
    -DWITH_GSTREAMER=OFF  \
    -DWITH_GPHOTO2=OFF  \
    -DWITH_MATLAB=OFF  \
    -DWITH_NVCUVID=OFF \
    -DWITH_OPENCL=OFF \
    -DWITH_OPENCLAMDBLAS=OFF \
    -DWITH_OPENCLAMDFFT=OFF \
    -DWITH_TIFF=OFF  \
    -DWITH_VTK=OFF  \
    -DWITH_WEBP=OFF  \
    ..
make -j8
OpenCV_DIR=$(pwd)
cd ../..

highlight "Installing Eigen3 ..."
git_clone "git clone --branch=3.4.0 --depth=1 https://gitlab.com/libeigen/eigen.git"
cd eigen
if [ ! -d build ]; then
  mkdir build
fi
if [ ! -d install ]; then
  mkdir install
fi
cd build
cmake -DCMAKE_INSTALL_PREFIX="$(pwd)/../install" ..
make -j8
make install
Eigen3_DIR="$(pwd)/../install/share/eigen3/cmake"
cd ../..

highlight "Installing Pangolin ..."
git_clone "git clone --recursive --depth=1 https://github.com/stevenlovegrove/Pangolin.git"
cd Pangolin
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake ..
make -j8
Pangolin_DIR=$(pwd)
cd ../..

highlight "Installing g2o ..."
cd g2o
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake -DEigen3_DIR="$Eigen3_DIR" ..
make -j8
cd ../..

highlight "Installing DBoW2 ..."
cd DBoW2
if [ ! -d build ]; then
  mkdir build
fi
cd build
echo "$OpenCV_DIR"
cmake -DOpenCV_DIR="$OpenCV_DIR" ..
make -j8
cd ../..

highlight "Installing Sophus ..."
cd Sophus
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake -DEigen3_DIR="$Eigen3_DIR" ..
make -j8
cd ../../..

highlight "Installing cnpy ..."
git_clone "git clone https://github.com/rogersce/cnpy.git"
cd cnpy
if [ ! -d build ]; then
  mkdir build
fi
cd build
cmake ..
make
sudo make install
cd ../..

highlight "Add keypoints dir ..."
if [ ! -d per_frame_keypoints ]; then
  mkdir per_frame_keypoints
fi

highlight "building ORB-SLAM3 ..."
if [ ! -d build ]; then
  mkdir build
fi
cd build

cmake \
  -DOpenCV_DIR="$OpenCV_DIR" \
  -DEigen3_DIR="$Eigen3_DIR" \
  -DPangolin_DIR="$Pangolin_DIR" \
  ..
make -j8
