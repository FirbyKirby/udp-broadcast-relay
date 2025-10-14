# Crashwalk Haunted House Control System

## Objective
Create a Docker image for Unraid systems with multiple VLAN support that functions as a UDP Broadcast Relay with the following requirements

## Key Features
- Accept configuration via both configuration files and environment variables
- Allow users to define broadcast ports and specify source and destination VLANs for relay operations
- Support multiple simultaneous VLAN configurations and broadcast ports
- Enable HDHomerun devices on one VLAN to broadcast to other VLANs while maintaining flexibility for other broadcast scenarios

## Technologies


## Significance
This project allows home users with highly segmented networks using VLANS to allow communication between IoT devices across segments.

## Deployment
Designed for deployment via docker on the Unraid OS.