# FPGA-Based FAST Corner Detection Accelerator

## Overview

This project implements the FAST (Features from Accelerated Segment Test) corner detection algorithm on an FPGA using Verilog HDL. The design processes grayscale images stored in memory, detects corner features in real time, and transmits detected corner coordinates to a host PC through UART for visualization.

The implementation includes Fixed Threshold, Global Adaptive Threshold, and Local Adaptive Threshold approaches to evaluate corner detection performance under different image illumination conditions.

The complete processing pipeline consists of image storage, pixel streaming, line buffering, sliding window generation, threshold computation, FAST corner detection, corner coordinate storage, UART transmission, and Python-based visualization.

## Hardware and Tools

* FPGA Board: Digilent Nexys A7-100T
* FPGA Device: Xilinx Artix-7
* Development Environment: Xilinx Vivado
* Software: Python, OpenCV, NumPy, PySerial

## Features

* FAST Corner Detection in Verilog
* Fixed Threshold Implementation
* Global Adaptive Threshold Implementation
* Local Adaptive Threshold Implementation
* UART-Based Corner Transmission
* Python Visualization Interface
* Non-Maximum Suppression (NMS)
* Support for 64×64, 128×128, and 256×256 Images

## Repository Structure

* `Image/` – Test images and generated HEX files
* `Python/` – Visualization and UART receiver scripts
* `Vivado/` – Verilog source files, constraints, and testbenches
* `Paper/` – Project documentation and reports