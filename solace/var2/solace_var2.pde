// Main config
int numCols = 32;
int numRows = 8;
int iteration = 0;
ArrayList<Integer> colors;
int colorIndex = 0;
float angleOffset = 0;
float centerOffset = 270; // Offset distance from the center
int targetFrameRate = 60; // Set your target frame rate here
int duration = 419; // Updated duration for a full rotation at 60 FPS

void setup() {
  size(1000, 1000); // Set the canvas size
  frameRate(targetFrameRate); // Set the frame rate
  colorMode(RGB, 255); // Use RGB mode for colors
  colors = new ArrayList<Integer>();
  for (int i = 0; i < 10; i++) {
    int gray = (int) map(i, 0, 9, 0, 255);
    colors.add(color(gray, gray, gray)); // Shades of gray colors
  }
  noFill();
  smooth();
}

void draw() {
  background(255); // Set background color to white
  noStroke();
  translate(width / 2, height / 2); // Move origin to the center of the canvas

  // Motion config:
  float progress = frameCount % duration;
  if (progress == 0) iteration++;

  // Rows and height config:
  int numRowsDrawn = numRows; // Keep the number of rows constant
  float rowHeight = height / (float) numRows;
  float radius = min(width, height) / 2;

  // Loop through each row:
  for (int y = 0; y < numRowsDrawn; y++) {
    // Calculate y position (from the bottom)
    float targetY = height - (y + 1) * rowHeight;
    // Position in the progress
    float currentY = map(progress, 0, duration, targetY, targetY + rowHeight);
    // Influence based on the Y position
    float yInfluence = map(currentY / (float) numRows, 0, rowHeight, 1, numRows + 1) * 0.7;
    // Double columns each row
    float extraCols = pow(2, yInfluence) - 1;

    // Loop through each column:
    for (int x = 0; x < numCols; x++) {
      // Skip drawing if out of bounds
      if (targetY > height) continue;

      // Size and position:
      float columnWidth = width / (float) numCols;
      float currentWidth = columnWidth + extraCols * columnWidth;
      float angle = map(x, 0, numCols, 0, TWO_PI) + angleOffset;
      float distance = map(y, 0, numRowsDrawn, centerOffset, radius); // Keep distance constant

      // Linear interpolation color:
      float amount = map(targetY % rowHeight, 0, rowHeight, 0, 1);
      color c1 = colors.get((colorIndex + y + x) % colors.size());
      color c2 = colors.get((colorIndex + y + x + 1) % colors.size());
      color c = lerpColor(c1, c2, amount);

      // Draw rectangle:
      fill(c);
      float posX = cos(angle) * distance;
      float posY = sin(angle) * distance;
      float rectWidth = currentWidth * 0.6; // Adjusted width
      float rectHeight = rowHeight * 0.4;   // Adjusted height
      pushMatrix();
      translate(posX, posY);
      rotate(angle);
      rect(0, 0, rectWidth, rectHeight);
      popMatrix();
    }
  }

  // Update color index and angle offset for changing color palette and rotation effect
  if (frameCount % 10 == 0) {
    colorIndex = (colorIndex + 1) % colors.size();
  }
  angleOffset += 0.015; // Slower rotation for smoother effect
}
