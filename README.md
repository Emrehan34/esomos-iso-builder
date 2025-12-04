   .github/workflows/build-iso.yml

   name: Build ESOMos ISO

on:
  workflow_dispatch:
  push:
    branches:
      - main
      - master

jobs:
  build-iso:
    runs-on: ubuntu-latest
    timeout-minutes: 60
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
    
    - name: Setup Arch Linux environment
      run: |
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
    
    - name: Install archiso
      run: |
        sudo pacman -Syu --noconfirm archiso base-devel git python python-pip
    
    - name: Make script executable
      run: |
        chmod +x build_esomos.sh || chmod +x ESOMos_Otomatik_Kurulum.sh
    
    - name: Build ISO
      run: |
        if [ -f "build_esomos.sh" ]; then
          ./build_esomos.sh
        elif [ -f "ESOMos_Otomatik_Kurulum.sh" ]; then
          ./ESOMos_Otomatik_Kurulum.sh
        else
          echo "❌ Build script not found!"
          exit 1
        fi
    
    - name: Find and upload ISO
      uses: actions/upload-artifact@v4
      with:
        name: esomos-iso
        path: |
          **/*.iso
          ~/Desktop/*.iso
          ~/esomos_build/out/*.iso
        retention-days: 7
        if-no-files-found: error
