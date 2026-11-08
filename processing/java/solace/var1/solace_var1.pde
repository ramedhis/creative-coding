int numCols = 32;
int numRows = 8;
int iteration = 0;
ArrayList<Integer> colors;
int colorIndex = 0;
float angleOffset = 0;
int targetFrameRate = 60; // Set your target frame rate here

void setup() {
  size(128, 128);
  frameRate(targetFrameRate); // Set the frame rate
  colorMode(RGB, 255); // Using RGB mode for black to white spectrum
  colors = new ArrayList<Integer>();
  for (int i = 0; i < 10; i++) {
    int gray = (int) map(i, 0, 9, 0, 255);
    colors.add(color(gray, gray, gray));
  }
  noFill();
  smooth();
}

void draw() {
  background(255);
  noStroke();
  translate(width / 2, height / 2); // Move origin to the center of the canvas

  // Animation settings:
  float duration = 64;
  float progress = frameCount % duration;
  if (progress == 0) iteration++;

  // Rows and height:
  int numRowsDrawn = numRows + 1 + iteration;
  float rowH = height / (float) numRows;
  float radius = min(width, height) / 2;

  // Offset for starting point adjustment:
  int startOffset = 5; // Adjust this to shift the starting point (5-10)

  // Loop through rows:
  for (int y = 0; y < numRowsDrawn; y++) {
    // Calculate y position (start at the bottom)
    float targetY = height - (y + 1 + startOffset) * rowH + iteration * rowH;
    // Where are we in the progress
    float currentY = map(progress, 0, duration, targetY, targetY + rowH);
    // What is the influence based on the Y position?
    float yInfluence = map(currentY / (float) numRows, 0, rowH, 1, numRows + 1) * 0.7;
    // Double columns each row
    float extraCols = pow(2, yInfluence) - 1;

    // Loop through columns:
    for (int x = 0; x < numCols; x++) {
      // Don't draw things out of screen 
      if (targetY > height) continue;

      // Size and position:
      float colW = width / (float) numCols;
      float currentW = colW + extraCols * (float) colW;
      float angle = map(x, 0, numCols, 0, TWO_PI) + angleOffset;
      float dist = map(y, 0, numRowsDrawn, 0, radius);

      // Lerp colour:
      float amount = map(targetY % rowH, 0, rowH, 0, 1);
      color c1 = colors.get((colorIndex + y + x) % colors.size());
      color c2 = colors.get((colorIndex + y + x + 1) % colors.size());
      color c = lerpColor(c1, c2, amount);

      // Draw:
      fill(c);
      float posX = cos(angle) * dist;
      float posY = sin(angle) * dist;
      float rectW = currentW * 0.4; // Adjusted for better fit
      float rectH = rowH * 0.4;     // Adjusted for better fit
      pushMatrix();
      translate(posX, posY);
      rotate(angle);
      rect(0, 0, rectW, rectH);
      popMatrix();
    }
  }

  // Update color index and angle offset to create a changing color palette and rotating effect over time
  if (frameCount % 10 == 0) {
    colorIndex = (colorIndex + 1) % colors.size();
  }
  angleOffset += 0.005; // Slower rotation for smoother effect
}
