int numVertices = 800;
PVector[] sphereVertices;
PVector[] smallSphereVertices;
PVector[] largeSphereVertices;
PVector[] centerSphereVertices;
PVector rippleOrigin;
PVector smallRippleOrigin;
PVector largeRippleOrigin;
float currentSize;
color colorSmall;
color colorMid;
color colorLarge;
int loopDuration = 7200; // Loop duration in frames (e.g., 7200 frames for a 2-minute loop at 60 FPS)
int frameNumber = 0; // Counter for frame saving
boolean exporting = true; // Set to false to stop exporting
String outputDir; // Absolute path to creative-coding-processing/output/solitude_var2

void setup() {
  size(1000, 1000, P3D);
  frameRate(60); // Set the frame rate to 60 FPS
  sphereVertices = new PVector[numVertices];
  smallSphereVertices = new PVector[numVertices];
  largeSphereVertices = new PVector[numVertices];
  calculateSphereVertices(sphereVertices, 200);
  calculateSphereVertices(smallSphereVertices, 170);
  calculateSphereVertices(largeSphereVertices, 240);
  rippleOrigin = sphereVertices[int(random(numVertices))];
  smallRippleOrigin = smallSphereVertices[int(random(numVertices))];
  largeRippleOrigin = largeSphereVertices[int(random(numVertices))];
  colorMid = color(255, 100, 0);
  colorSmall = color(0, 155, 255);
  colorLarge = color(100, 255, 100);
  currentSize = 4.0;
  centerSphereVertices = new PVector[numVertices];
  calculateCenterSphereVertices();
  
  // Create the output directory (creative-coding-processing/output/solitude_var2) if it doesn't exist
  // Sketch lives at creative-coding-processing/solitude/var2/, so we go up two levels to the repo root
  outputDir = sketchPath("../../output/solitude_var2");
  File outDirFile = new File(outputDir);
  if (!outDirFile.exists()) {
    outDirFile.mkdirs();
  }
}

void draw() {
  background(0);
  lights();
  translate(width / 2, height / 2);

  int currentFrame = frameCount % loopDuration; // Loop frame count within the loop duration

  drawRotatingSphere(sphereVertices, rippleOrigin, colorMid, 0.03, 10, 0.005, 1, 0.03, 0.05, 23.5, 2.0, 6.0, 0.4, currentFrame);
  drawRotatingSphere(smallSphereVertices, smallRippleOrigin, colorSmall, -0.03, 10, -0.005, 0.85, 0.03, 0.05, 23.5, 2.0, 6.0, 0.2, currentFrame);
  drawRotatingSphere(largeSphereVertices, largeRippleOrigin, colorLarge, 0.02, 5, 0.007, 1.2, 0.02, 0.05, 23.5, 2.0, 6.0, 0.6, currentFrame);
  drawCenterSphereDots(centerSphereVertices, 0.02, 2.0, 50.0, currentFrame);

  if (exporting) {
    // Save the current frame as a PNG into the repo's output/solitude_var2 folder
    String filename = outputDir + "/frame_" + nf(frameNumber, 4) + ".png"; // Adjust nf for padding
    saveFrame(filename);
    frameNumber++;
    
    // Stop exporting after saving all frames in the loop duration
    if (frameNumber >= loopDuration) {
      exporting = false;
      println("Exporting completed.");
    }
  }
}

void drawRotatingSphere(PVector[] vertices, PVector rippleOrigin, color baseColor, float rippleSpeed, float rippleAmplitude, float rotationSpeed, float scale, float blinkSpeed, float rippleFrequency, float tiltAngle, float minDotSize, float maxDotSize, float shakeAmount, int currentFrame) {
  pushMatrix();
  rotateX(radians(tiltAngle));
  rotateY(currentFrame * rotationSpeed);
  drawSphere(vertices, rippleOrigin, rippleSpeed, baseColor, scale, rippleAmplitude, rippleFrequency, blinkSpeed, minDotSize, maxDotSize, shakeAmount, currentFrame);
  popMatrix();
}

void drawSphere(PVector[] vertices, PVector rippleOrigin, float rippleSpeed, color baseColor, float scale, float rippleAmplitude, float rippleFrequency, float blinkSpeed, float minDotSize, float maxDotSize, float shakeAmount, int currentFrame) {
  noFill();
  float blinkAmount = map(sin(currentFrame * blinkSpeed), -1, 1, 0, 1);
  float targetSize = map(blinkAmount, 0, 1, minDotSize, maxDotSize);
  currentSize = lerp(currentSize, targetSize, 0.05);
  strokeWeight(currentSize);
  float pulseAmount = map(sin(currentFrame * 0.02), -1, 1, 0.8, 1.2);
  beginShape(POINTS);
  for (int i = 0; i < vertices.length; i++) {
    float distance = PVector.dist(vertices[i], rippleOrigin);
    float rippleEffect = sin(distance * rippleFrequency - currentFrame * rippleSpeed) * rippleAmplitude;
    float x = vertices[i].x * pulseAmount * scale + rippleEffect;
    float y = vertices[i].y * pulseAmount * scale + rippleEffect;
    float z = vertices[i].z * pulseAmount * scale + rippleEffect;
    PVector shakenVertex = new PVector(x + random(-shakeAmount, shakeAmount), y + random(-shakeAmount, shakeAmount), z + random(-shakeAmount, shakeAmount));
    float shade = map(shakenVertex.z, -200 * scale, 200 * scale, 0, 255);
    color vertexColor = lerpColor(color(0), color(255), shade / 255.0);
    stroke(vertexColor);
    vertex(shakenVertex.x, shakenVertex.y, shakenVertex.z);
  }
  endShape();
}

void drawCenterSphereDots(PVector[] vertices, float pulseSpeed, float minSize, float maxSize, int currentFrame) {
  pushMatrix();
  float pulseAmountCenter = map(sin(currentFrame * pulseSpeed), -1, 1, 0.8, 1.2);
  float centerDotSize = minSize + (maxSize - minSize) * pulseAmountCenter;
  stroke(color(255));
  strokeWeight(centerDotSize);
  beginShape(POINTS);
  for (int i = 0; i < vertices.length; i++) {
    vertex(vertices[i].x, vertices[i].y, vertices[i].z);
  }
  endShape();
  popMatrix();
}

void calculateSphereVertices(PVector[] vertices, float radius) {
  float goldenRatio = (1 + sqrt(5)) / 2;
  float angleIncrement = TWO_PI / goldenRatio;
  for (int i = 0; i < numVertices; i++) {
    float inclination = acos(1 - 2.0 * i / numVertices);
    float azimuth = angleIncrement * i;
    vertices[i] = new PVector(
      sin(inclination) * cos(azimuth) * radius,
      sin(inclination) * sin(azimuth) * radius,
      cos(inclination) * radius
    );
  }
}

void calculateCenterSphereVertices() {
  for (int i = 0; i < numVertices; i++) {
    centerSphereVertices[i] = new PVector(0, 0, 0);
  }
}
