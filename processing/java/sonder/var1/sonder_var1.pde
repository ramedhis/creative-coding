// For global variable and constant:
static final int BORDER_X = 20; // Border size for x-asis
static final int BORDER_Y = 20; // Border size for y-axis
int s; // For keeping track of the seconds
int m; // For keeping track of the minutes
int h; // For keeping track of the hours 

void setup() {
  size(500, 500);  // Set canvas size
  background(255);  // White background
}

void draw() {
  // Get the current time
  s = second(); // Current second
  m = minute(); // Current minute
  h = hour() % 12; // Current hour in 12-hour format

  // Draw larger circular clock face
  noStroke();  // Remove outer lines (outline) from the clock face
  fill(255);  // White color for the clock face
  float clockDiameter = height - BORDER_Y;  // Set clock diameter
  ellipse(width / 2, height / 2, clockDiameter, clockDiameter);  // Draw clock face

  // Draw hour markers as straight lines pointing to the center
  strokeWeight(4);
  for (int i = 0; i < 12; i++) {
    float angle = TWO_PI / 12 * i;
    
    // Define the start (outer) and end (inner) points of each line
    float outerX = width / 2 + cos(angle) * (clockDiameter / 2 - 20);  // Outer end of line
    float outerY = height / 2 + sin(angle) * (clockDiameter / 2 - 20);
    float innerX = width / 2 + cos(angle) * (clockDiameter / 2 - 40);  // Inner end of line
    float innerY = height / 2 + sin(angle) * (clockDiameter / 2 - 40);

    // Change color for the current hour marker
    if (i == h) {
      stroke(255, 0, 0);  // Red color for the current hour marker
    } else {
      stroke(0);  // Black color for other hour markers
    }

    // Draw straight hour marker line
    line(outerX, outerY, innerX, innerY);
  }

  // Draw second markers as straight lines pointing to the center
  strokeWeight(2);
  for (int i = 0; i < 60; i++) {
    float angle = TWO_PI / 60 * i;

    // Define the start (outer) and end (inner) points of each line
    float outerX = width / 2 + cos(angle) * (clockDiameter / 2 - 60);  // Outer end of line for seconds
    float outerY = height / 2 + sin(angle) * (clockDiameter / 2 - 60);
    float innerX = width / 2 + cos(angle) * (clockDiameter / 2 - 80);  // Inner end of line for seconds
    float innerY = height / 2 + sin(angle) * (clockDiameter / 2 - 80);

    // Change color for the current second's marker
    if (i == s) {
      stroke(255, 0, 0);  // Red color for the current second marker
    } else {
      stroke(150);  // Gray color for other second markers
    }

    // Draw straight second marker line
    line(outerX, outerY, innerX, innerY);
  }

  // Draw minute hand
  float minuteAngle = map(m, 0, 60, 0, TWO_PI) - HALF_PI;
  stroke(0);  // Black color for minutes hand
  strokeWeight(4);
  line(width / 2, height / 2, width / 2 + cos(minuteAngle) * (clockDiameter / 2 - 60), height / 2 + sin(minuteAngle) * (clockDiameter / 2 - 60));
}
