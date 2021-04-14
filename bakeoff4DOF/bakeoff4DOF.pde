import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0;             //starts at zero-ith trial
float border = 0;          //some padding from the sides of window
int trialCount = 12;       //this will be set higher for the bakeoff
int trialIndex = 0;        //what trial are we on
int errorCount = 0;        //used to keep track of errors
float errorPenalty = 0.5f; //for every error, add this value to mean time
int startTime = 0;         // time starts when the first click is captured
int finishTime = 0;        //records the time of the final click
boolean userDone = false;  //is the user done

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch.

//These variables are for my example design. Your input code should modify/replace these!
float dragOffsetX = 0;
float dragOffsetY = 0;
boolean mouseFirstPressed = false;
boolean mouseMove = false;
boolean mouseRotandSize = false;
float currAngle = 0;
float c_angle = 0;
int timeFirstClick = -1;
float refX = 0;
float refY = 0;

float logoX = 0;
float logoY = 0;
float logoZ = 50f;
float logoRotation = 0;

private class Destination
{
    float x = 0;
    float y = 0;
    float rotation = 0;
    float z = 0;
}

ArrayList<Destination> destinations = new ArrayList<Destination>();

void setup() {
    size(1000, 800);
    rectMode(CENTER);
    textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
    textAlign(CENTER);

    //don't change this!
    border = inchToPix(2f); //padding of 1.0 inches

    for (int i = 0; i < trialCount; i++) //don't change this!
        {
        Destination d = new Destination();
        d.x = random(- width / 2 + border, width / 2 - border); //set a random x with some padding
        d.y = random(- height / 2 + border, height / 2 - border); //set a random y with some padding
        d.rotation = random(0, 360); //random rotation between 0 and 360
        int j = (int)random(20);
        d.z = ((j % 12) + 1) * inchToPix(.25f); //increasing size from .25 up to 3.0"
        destinations.add(d);
        println("created target with " + d.x + "," + d.y + "," + d.rotation + "," + d.z);
    }

    Collections.shuffle(destinations); // randomize the order of the button; don't change this.
}



void draw() {

    background(40); //background is dark grey
    fill(200);
    noStroke();

    //shouldn't really modify this printout code unless there is a really good reason to
    if (userDone)
        {
        text("User completed " + trialCount + " trials", width / 2, inchToPix(.4f));
        text("User had " + errorCount + " error(s)", width / 2, inchToPix(.4f) * 2);
        text("User took " + (finishTime - startTime) / 1000f / trialCount + " sec per destination", width / 2, inchToPix(.4f) * 3);
        text("User took " + ((finishTime - startTime) / 1000f / trialCount + (errorCount * errorPenalty)) + " sec per destination inc. penalty", width / 2, inchToPix(.4f) * 4);
        return;
    }

    //===========DRAW DESTINATION SQUARES=================
    for (int i = trialIndex; i < trialCount; i++) // reduces over time
        {
        pushMatrix();
        translate(width / 2, height / 2); //center the drawing coordinates to the center of the screen
        Destination d = destinations.get(i);
        translate(d.x, d.y); //center the drawing coordinates to the center of the screen
        rotate(radians(d.rotation));
        noFill();
        strokeWeight(3f);
        if (trialIndex == i)
            stroke(255, 0, 0, 192); //set color to semi translucent
        else
            stroke(128, 128, 128, 128); //set color to semi translucent
        rect(0, 0, d.z, d.z);
        popMatrix();
    }

    // DRAW TEXT THAT SAYS WHAT NEEDS CHANGING
    String offTargetAttributes = "";
    if (!checkForDistSuccess()) {
        offTargetAttributes += " Distance";
    }
    if (!checkForRotationSuccess()) {
        offTargetAttributes += " Rotation";
    }
    if (!checkForZSuccess()) {
        offTargetAttributes += " Scale";
    }
    if (offTargetAttributes.length() > 0) {
        text("Off-target:" + offTargetAttributes, width / 2, inchToPix(.4f));
    }

    //===========DRAW LOGO SQUARE=================
    pushMatrix();
    translate(width / 2, height / 2); //center the drawing coordinates to the center of the screen
    translate(logoX, logoY);
    rotate(logoRotation + (currAngle - c_angle));
    noStroke();
    if (checkSuccessNoPrint()) {
        fill(60, 255, 192, 192);
    } else {
        fill(60, 60, 192, 192);
    }
    rect(0, 0, logoZ, logoZ);

    // draw guide square at same translation
    Destination targetD = destinations.get(trialIndex);
    rotate(-(logoRotation + (currAngle - c_angle)));
    rotate(radians(targetD.rotation));
    noFill();
    stroke(204, 102, 0);
    strokeWeight(1);
    rect(0, 0, targetD.z, targetD.z);
    noStroke();
    popMatrix();

    //===========DRAW EXAMPLE CONTROLS=================
    fill(255);

    scaffoldControlLogic(); //you are going to want to replace this!
    text("Trial " + (trialIndex + 1) + " of " + trialCount, width / 2, inchToPix(.8f));
}

//my example design for control, which is terrible
void scaffoldControlLogic()
{
    float adjMouseX = mouseX - (width / 2);
    float adjMouseY = mouseY - (height / 2);

    // visualizeMousePoint();
    // println("mouseInLogoSquare: " + mouseInLogoSquare(adjMouseX, adjMouseY));

    if (mousePressed && !mouseFirstPressed) {
        mouseFirstPressed = true;
        if (mouseInLogoSquare(adjMouseX, adjMouseY)) {
            mouseMove = true;
            dragOffsetX = adjMouseX - logoX;
            dragOffsetY = adjMouseY - logoY;
        } else {
          c_angle = atan2(mouseY - height / 2 - logoY, mouseX - width / 2 - logoX); //The initial mouse rotation
          currAngle = atan2(mouseY - height / 2 - logoY, mouseX - width / 2 - logoX);
          //q_angle = logoRotation; //Initial box rotation
          refX = mouseX;
          refY = mouseY;
          mouseRotandSize = true;
        }

    }

    //left middle, move left
    if (mousePressed && mouseMove) {
      logoX = adjMouseX - dragOffsetX;
      logoY = adjMouseY - dragOffsetY;
    }
}

boolean mouseInLogoSquare(float adjMouseX, float adjMouseY) {
    // println("logo:        (" + logoX + ", " + logoY + ")");
    // println("logoZ:       " + -1.f * halfZ);
    // println("logo bounds: ([" + (logoX - logoZ) + ", " + (logoX + logoZ) + "], [" + (logoY - logoZ) + ", " + (logoY + logoZ) + "])");

    float halfZ = logoZ / 2;

    float mouseVecX = adjMouseX - logoX;
    float mouseVecY = adjMouseY - logoY;

    float oppLogoRotRads = - radians(logoRotation);
    // println("logoRotation: " + logoRotation);

    float rotMouseX = cos(oppLogoRotRads) * mouseVecX - sin(oppLogoRotRads) * mouseVecY;
    float rotMouseY = sin(oppLogoRotRads) * mouseVecX + cos(oppLogoRotRads) * mouseVecY;

    return rotMouseX >= - 1.f * halfZ && rotMouseX <= halfZ && rotMouseY >= - 1.f * halfZ && rotMouseY <= halfZ;
}

void visualizeMousePoint() {
    float adjMouseX = mouseX - (width / 2);
    float adjMouseY = mouseY - (height / 2);

    float halfZ = logoZ / 2;

    float mouseVecX = adjMouseX - logoX;
    float mouseVecY = adjMouseY - logoY;

    float oppLogoRotRads = - radians(logoRotation);

    float rotMouseX = cos(oppLogoRotRads) * mouseVecX - sin(oppLogoRotRads) * mouseVecY;
    float rotMouseY = sin(oppLogoRotRads) * mouseVecX + cos(oppLogoRotRads) * mouseVecY;
    circle(width / 2 + logoX + rotMouseX, height / 2 + logoY + rotMouseY, 5);

    println("rot mouse: (" + rotMouseX + ", " + rotMouseY + ")");
    println("logoZ:     [" + ( - 1.f * halfZ) + ", " + halfZ + "]");

    pushMatrix();
    translate(width / 2, height / 2); //center the drawing coordinates to the center of the screen
    translate(logoX, logoY);
    // rotate(radians(logoRotation));
    noStroke();
    fill(255, 0, 0, 100);
    rect(0, 0, logoZ, logoZ);
    popMatrix();
}

void mousePressed()
{
    if (startTime == 0) //start time on the instant of the first user click
        {
        startTime = millis();
        println("time started!");
    }

}


void mouseReleased()
{
    //check to see if user clicked middle of screen within 3 inches, which this code uses as a submit button
    /* if (dist(width / 2, height / 2, mouseX, mouseY)<inchToPix(3f))
    {
    if (userDone == false && !checkForSuccess())
    errorCount++;

    trialIndex++; //and move on to next trial

    if (trialIndex == trialCount && userDone == false)
    {
    userDone = true;
    finishTime = millis();
}
} */
  mouseFirstPressed = false;
  mouseMove = false;
  mouseRotandSize = false;

  if (millis() - timeFirstClick <= 250){
    if (userDone==false && !checkForSuccess())
      errorCount++;

    trialIndex++; //and move on to next trial

    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }

    timeFirstClick = -1;
    return;
  }
  timeFirstClick = millis();

  logoRotation -= c_angle - currAngle;
  c_angle = 0;
  currAngle = 0;
}

void mouseDragged(){
    if(mouseRotandSize){
      currAngle = atan2(mouseY - height / 2 - logoY, mouseX - width / 2 - logoX);

      logoZ += round(dist(mouseX, mouseY, logoX + width / 2, logoY + height / 2) - dist(refX, refY, logoX + width / 2, logoY + height/2));
      logoZ = constrain(logoZ, 0, logoZ);
      refX = mouseX;
      refY = mouseY;
    }
}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
    Destination d = destinations.get(trialIndex);
    boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
    boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, degrees(logoRotation))<= 5;
    boolean closeZ = abs(d.z - logoZ)<inchToPix(.05f); //has to be within +-0.05"

    println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logoX + "/" + logoY + ")");
    println("Close Enough Rotation: " + closeRotation + " (rot dist=" + calculateDifferenceBetweenAngles(d.rotation, logoRotation) + ")");
    println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ + ")");
    println("Close enough all: " + (closeDist && closeRotation && closeZ));

    return closeDist && closeRotation && closeZ;
}

public boolean checkForDistSuccess()
{
    Destination d = destinations.get(trialIndex);
    boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
    // boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, degrees(logoRotation))<= 5;
    // boolean closeZ = abs(d.z - logoZ)<inchToPix(.05f); //has to be within +-0.05"

    // println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logoX + "/" + logoY + ")");
    // println("Close Enough Rotation: " + closeRotation + " (rot dist=" + calculateDifferenceBetweenAngles(d.rotation, logoRotation) + ")");
    // println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ + ")");
    // println("Close enough all: " + (closeDist && closeRotation && closeZ));

    return closeDist;
}

public boolean checkForRotationSuccess()
{
    Destination d = destinations.get(trialIndex);
    // boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
    boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, degrees(logoRotation + (currAngle - c_angle)))<= 5;
    // boolean closeZ = abs(d.z - logoZ)<inchToPix(.05f); //has to be within +-0.05"

    // println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logoX + "/" + logoY + ")");
    // println("Close Enough Rotation: " + closeRotation + " (rot dist=" + calculateDifferenceBetweenAngles(d.rotation, logoRotation) + ")");
    // println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ + ")");
    // println("Close enough all: " + (closeDist && closeRotation && closeZ));

    return closeRotation;
}

public boolean checkForZSuccess()
{
    Destination d = destinations.get(trialIndex);
    // boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
    // boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, degrees(logoRotation))<= 5;
    boolean closeZ = abs(d.z - logoZ)<inchToPix(.05f); //has to be within +-0.05"

    // println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logoX + "/" + logoY + ")");
    // println("Close Enough Rotation: " + closeRotation + " (rot dist=" + calculateDifferenceBetweenAngles(d.rotation, logoRotation) + ")");
    // println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ + ")");
    // println("Close enough all: " + (closeDist && closeRotation && closeZ));

    return closeZ;
}

public boolean checkSuccessNoPrint()
{
  return checkForDistSuccess() && checkForRotationSuccess() && checkForZSuccess();
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
    double diff = abs(a1 - a2);
    diff %= 90;
    if (diff > 45)
        return 90 - diff;
    else
        return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
    return inch * screenPPI;
}
