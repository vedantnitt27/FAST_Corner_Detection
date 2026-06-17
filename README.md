# FPGA FAST Corner Detection

## Overview
This project implements the FAST (Features from Accelerated Segment Test) corner detection algorithm on FPGA using Verilog.

## Features
- Image ROM using HEX files
- Pixel streaming architecture
- FAST corner detection
- UART transmission of corner coordinates
- Python visualization tool
- Non-Maximum Suppression (NMS)

## Hardware
- Nexys A7-100T FPGA
- Vivado Design Suite

## Results
- Tested on 64×64 images
- Extended to 128×128 and 256×256 images
- Real-time corner visualization on PC