int numVertices = 500; // Number of vertices
PVector[] sphereVertices;
PVector[] smallSphereVertices;
PVector[] largeSphereVertices;
PVector rippleOrigin; // Origin point of the ripple
PVector smallRippleOrigin; // Origin point of the ripple for the smaller sphere
PVector largeRippleOrigin; // Origin point of the ripple for the larger sphere
float rippleSpeed = 0.03; // Speed of the ripple effect (faster)
float rippleFrequency = 0.05; // Frequency of the ripple effect (lower)
float rippleAmplitude = 10; // Amplitude of the ripple effect (less aggressive)
float smallRippleSpeed = -0.03; // Speed of the ripple effect for the smaller sphere (opposite)
float largeRippleSpeed = 0.02; // Speed of the ripple effect for the larger sphere (different)
float largeRippleAmplitude = 5; // Reduced amplitude for the larger sphere
float rotationSpeed = 0.005; // Initial rotation speed, adjust this value as needed
float smallRotationSpeed = -0.005; // Initial rotation speed for the smaller sphere (opposite)
float largeRotationSpeed = 0.007; // Initial rotation speed for the larger sphere (different)
float tiltAngle = 23.5; // Earth's axial tilt angle in degrees
color royalOrange; // Color variable for Royal Orange
color oppositeColor; // Color variable for the opposite color
color largeColor; // Color variable for the larger sphere
float blinkSpeed = 0.01; // Speed of blinking effect
float blinkAmount = 0.0; // Amount of blink effect (0 to 1)
float dotSizeMin = 2.0; // Minimum size of each dot
float dotSizeMax = 6.0; // Maximum size of each dot
float sizeChangeSpeed = 0.05; // Speed of size change
float currentSize; // Current size of the dots
float shakeAmount = 0.2; // Amount of shaking effect (reduced for smoother effect)
float pulseSpeed = 0.02; // Speed of pulsating effect
float pulseAmount = 0.0; // Amount of pulsating effect

void setup() {
  size(700, 700, P3D); // Set the size of the window to 700x700 pixels and enable 3D rendering
  sphereVertices = new PVector[numVertices];
  smallSphereVertices = new PVector[numVertices];
  largeSphereVertices = new PVector[numVertices];
  calculateSphereVertices();
  calculateSmallSphereVertices();
  calculateLargeSphereVertices();
  rippleOrigin = sphereVertices[int(random(numVertices))]; // Choose a random vertex as the ripple origin
  smallRippleOrigin = smallSphereVertices[int(random(numVertices))]; // Choose a random vertex as the ripple origin for the smaller sphere
  largeRippleOrigin = largeSphereVertices[int(random(numVertices))]; // Choose a random vertex as the ripple origin for the larger sphere
  
  // Define Royal Orange color (RGB values)
  royalOrange = color(255, 100, 0);
  // Define the opposite color (RGB values)
  oppositeColor = color(0, 155, 255);
  // Define the color for the larger sphere (RGB values)
  largeColor = color(100, 255, 100);
  
  // Initialize currentSize to dotSizeMin
  currentSize = dotSizeMin;
}

void draw() {
  background(0); // Clear the screen with a black background
  lights(); // Add default lighting to the scene
  translate(width / 2, height / 2); // Move the origin to the center of the window
  
  // Draw the first sphere
  pushMatrix();
  rotateX(radians(tiltAngle));
  rotateY(frameCount * rotationSpeed); 
  drawSphere(sphereVertices, rippleOrigin, rippleSpeed, royalOrange, 1);
  popMatrix();
  
  // Draw the second (smaller) sphere
  pushMatrix();
  rotateX(radians(tiltAngle));
  rotateY(frameCount * smallRotationSpeed); 
  drawSphere(smallSphereVertices, smallRippleOrigin, smallRippleSpeed, oppositeColor, 0.85);
  popMatrix();
  
  // Draw the third (larger) sphere
  pushMatrix();
  rotateX(radians(tiltAngle));
  rotateY(frameCount * largeRotationSpeed); 
  drawSphere(largeSphereVertices, largeRippleOrigin, largeRippleSpeed, largeColor, 1.2);
  popMatrix();
}

void drawSphere(PVector[] vertices, PVector rippleOrigin, float rippleSpeed, color baseColor, float scale) {
  noFill();
  
  // Calculate blink effect using smooth transition (fade in and fade out)
  float blink = map(sin(frameCount * blinkSpeed), -1, 1, 0, 1);
  blinkAmount = blink; // Update blinkAmount for smooth transition
  
  // Calculate size based on blink effect
  float targetSize = map(blinkAmount, 0, 1, dotSizeMin, dotSizeMax);
  currentSize = lerp(currentSize, targetSize, sizeChangeSpeed); // Smoothly change size
  
  strokeWeight(currentSize); // Set stroke weight to control dot size
  
  // Calculate pulse effect
  pulseAmount = map(sin(frameCount * pulseSpeed), -1, 1, 0.8, 1.2);
  
  beginShape(POINTS); // Start drawing points
  for (int i = 0; i < vertices.length; i++) {
    // Calculate distance from the ripple origin
    float distance = PVector.dist(vertices[i], rippleOrigin);
    
    // Calculate ripple effect based on distance and time
    float rippleEffect = sin(distance * rippleFrequency - frameCount * rippleSpeed) * (scale == 1.2 ? largeRippleAmplitude : rippleAmplitude);
    
    // Apply ripple effect to the vertex
    float x = vertices[i].x * pulseAmount * scale + rippleEffect;
    float y = vertices[i].y * pulseAmount * scale + rippleEffect;
    float z = vertices[i].z * pulseAmount * scale + rippleEffect;
    
    // Add shaking effect
    float dx = random(-shakeAmount, shakeAmount);
    float dy = random(-shakeAmount, shakeAmount);
    float dz = random(-shakeAmount, shakeAmount);
    
    PVector shakenVertex = new PVector(x + dx, y + dy, z + dz);
    
    // Calculate 3D shading based on z-coordinate
    float shade = map(shakenVertex.z, -200 * scale, 200 * scale, 0, 255);
    color vertexColor = lerpColor(color(255, 0, 0), baseColor, shade / 255.0);
    stroke(vertexColor);
    
    vertex(shakenVertex.x, shakenVertex.y, shakenVertex.z);
  }
  endShape();
}

void calculateSphereVertices() {
  float goldenRatio = (1 + sqrt(5)) / 2;
  float angleIncrement = TWO_PI / goldenRatio;
  
  for (int i = 0; i < numVertices; i++) {
    float inclination = acos(1 - 2.0 * i / numVertices);
    float azimuth = angleIncrement * i;
    
    float x = sin(inclination) * cos(azimuth) * 200;
    float y = sin(inclination) * sin(azimuth) * 200;
    float z = cos(inclination) * 200;
    
    sphereVertices[i] = new PVector(x, y, z);
  }
}

void calculateSmallSphereVertices() {
  float goldenRatio = (1 + sqrt(5)) / 2;
  float angleIncrement = TWO_PI / goldenRatio;
  
  for (int i = 0; i < numVertices; i++) {
    float inclination = acos(1 - 2.0 * i / numVertices);
    float azimuth = angleIncrement * i;
    
    float x = sin(inclination) * cos(azimuth) * 170; // 85% of the original sphere
    float y = sin(inclination) * sin(azimuth) * 170; // 85% of the original sphere
    float z = cos(inclination) * 170; // 85% of the original sphere
    
    smallSphereVertices[i] = new PVector(x, y, z);
  }
}

void calculateLargeSphereVertices() {
  float goldenRatio = (1 + sqrt(5)) / 2;
  float angleIncrement = TWO_PI / goldenRatio;
  
  for (int i = 0; i < numVertices; i++) {
    float inclination = acos(1 - 2.0 * i / numVertices);
    float azimuth = angleIncrement * i;
    
    float x = sin(inclination) * cos(azimuth) * 240; // 120% of the original sphere
    float y = sin(inclination) * sin(azimuth) * 240; // 120% of the original sphere
    float z = cos(inclination) * 240; // 120% of the original sphere
    
    largeSphereVertices[i] = new PVector(x, y, z);
  }
}
