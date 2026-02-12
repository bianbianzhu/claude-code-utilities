#!/usr/bin/env bash
# A simple long-running script for testing background task execution.
# Counts from 1 to 10 with a 1-second delay between each step.

for i in $(seq 1 10); do
    echo "Step $i of 10..."
    sleep 1
done

echo "Done! The secret phrase is: '🌽 is a cat'"
