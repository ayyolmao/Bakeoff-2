import java.util.ArrayList;
import java.util.Collections;
import processing.sound.*;

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
int timeFirstClick = - 1;
float refX = 0;
float refY = 0;

float logoX = 0;
float logoY = 0;
float logoZ = 50f;
float logoRotation = 0;

float dragCircleRadius = 100;
float handleLength = 70;
color successGreen = color(60, 255, 50, 255);

Sound s;

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

    SinOsc sin = new SinOsc(this);
    sin.play(150, 0.5);

    s = new Sound(this);
    s.volume(0.1);

    Collections.shuffle(destinations); // randomize the order of the button; don't change this.
}



void draw() {

    background(40); //background is dark grey
    fill(200);
    noStroke();

    //shouldn't really modify this printout code unless there is a really good reason to
    if (userDone)
        {
            s.volume(0);
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

    //===========DRAW LOGO SQUARE=================
    Destination targetD = destinations.get(trialIndex);

    pushMatrix();
    translate(width / 2, height / 2); //center the drawing coordinates to the center of the screen
    translate(logoX, logoY);

    // check if we need to rotate
    rotate(radians(getClosestTargetRot(targetD.rotation)));
    float globalX = screenX(targetD.z + handleLength, targetD.z + handleLength);
    float globalY = screenY(targetD.z + handleLength, targetD.z + handleLength);
    float buffer = 30;
    println("globalX:" + globalX);
    println("globalY:" + globalY);
    if ((globalX > width - buffer || globalX < buffer) || (globalY > height - buffer || globalY < buffer)) {
        logoRotation += PI / 2;
        println("rotating");
    }
    rotate( - radians(getClosestTargetRot(targetD.rotation)));


    rotate(logoRotation + (currAngle - c_angle));

    // sound feedback
    if (checkSuccessNoPrint()) {
        s.volume(1.0);
    } else if (checkForRotationSuccess() && checkForZSuccess()) {
        s.volume(0.3);
    } else if (checkForDistSuccess()) {
        s.volume(0.3);
    } else {
        s.volume(0.1);
    }



    noStroke();

    // color using x/y coords
    fill(getLogoSquareColor(targetD));

    rect(0, 0, logoZ, logoZ);
    stroke(getHandleColor(getClosestTargetRot(targetD.rotation)));

    strokeWeight(3);
    line(logoZ / 2, logoZ / 2, logoZ + handleLength - 12, logoZ + handleLength - 12);
    color transparent_orange = color(204, 102, 0, 0);
    fill(transparent_orange);
    strokeWeight(8);
    circle(logoZ + handleLength, logoZ + handleLength, 37);
    strokeWeight(3);
    line(logoZ + handleLength + 12, logoZ + handleLength + 12, logoZ + handleLength + 50, logoZ + handleLength + 50);

    // draw faded handle knob
    // fill(255,255,255,20);
    // noStroke();
    // circle(logoZ + handleLength + 75, logoZ + handleLength + 75, 75);

    //===========DRAW DRAG CIRCLE=================
    if (logoZ < dragCircleRadius - 20) {
        fill(255,255,255,30);
        noStroke();
        circle(0,0,dragCircleRadius);
    }

    //===========DRAW GUIDE SQUARE=================
    rotate(- (logoRotation + (currAngle - c_angle)));

    // println("targetD.rotation: " + targetD.rotation);
    rotate(radians(getClosestTargetRot(targetD.rotation)));
    noFill();
    stroke(204, 102, 0, 255);
    strokeWeight(1);
    rect(0, 0, targetD.z, targetD.z);
    //line(targetD.z / 2, targetD.z / 2, targetD.z + 50, targetD.z + 50);
    color orange = color(204, 102, 0, 192);
    fill(orange);
    circle(targetD.z + handleLength, targetD.z + handleLength, 20);
    noStroke();
    popMatrix();

    //===========DRAW EXAMPLE CONTROLS=================
    fill(255);

    scaffoldControlLogic(); //you are going to want to replace this!
    text("Trial " + (trialIndex + 1) + " of " + trialCount, width / 2, inchToPix(.8f));
}

float getClosestTargetRot(float targetDRotation) {
    // calculate closest 90 degree target rotation
    float closestTargetRot = targetDRotation;
    for (int i = 0; i < 4; i++) {
        float temp = targetDRotation + (i * 90);
        if (angleDistance(degrees(logoRotation), temp) < angleDistance(degrees(logoRotation), closestTargetRot)) {
            closestTargetRot = temp;
        }
    }
    return closestTargetRot;
}

float angleDistance(float deg1, float deg2) {
    float phi = abs(deg1 - deg2) % 360;
    float distance = phi > 180 ? 360 - phi : phi;
    return distance;
}

color getHandleColor(float targetDRotation) {
    // from: white
    color from = color(255, 255, 255, 255);
    // to: blue
    color to = color(60, 60, 255, 255);
    // println("check");
    float logRot = logoRotation + (currAngle - c_angle);
    // println("logoRotation: " + degrees(logoRotation + (currAngle - c_angle)));
    if (checkForRotationSuccess() && checkForZSuccess()) {
        return successGreen;
    }
    float degDiff = (float)calculateDifferenceBetweenAngles(targetDRotation, degrees(logRot));
    float percentageDiff = map(degDiff, 0, 45, 1, 0);
    // float blueLerp = map(percentageDiff, 0.f, 1.f, 255, 100);
    // float redLerp = map(percentageDiff, 0.f, 1.f, 255, 60);
    // println("closestTargetRotation: " + targetDRotation);
    // println("degDiff: " + degDiff);
    // println("percentageDiff: " + percentageDiff);
    return lerpColor(from, to, percentageDiff);
    // return color(redLerp, blueLerp, 255, 255);
}

color getLogoSquareColor(Destination targetDest) {
    // from: white
    color from = color(255, 255, 255, 190);
    // to: blue
    color to = color(60, 60, 255, 190);
    if (checkForDistSuccess()) {
        return successGreen;
    }
    float distDiff = dist(targetDest.x, targetDest.y, logoX, logoY);
    float percentageDiff = map(distDiff, 0, 1000, 1, 0);
    // println("distDiff: " + distDiff);
    // println("percentageDiff: " + percentageDiff);
    return lerpColor(from, to, percentageDiff);
}

//my example design for control, which is terrible
void scaffoldControlLogic()
{
    float adjMouseX = mouseX - (width / 2);
    float adjMouseY = mouseY - (height / 2);

    if (!checkForZSuccess() || !checkForRotationSuccess()) {
        text("SCALE", logoX + width / 2, logoY + height / 2 - logoZ / 2 - 20);
    } else {
        text("DRAG", logoX + width / 2, logoY + height / 2 - logoZ / 2 - 20);
    }

    // visualizeMousePoint();
    // println("mouseInLogoSquare: " + mouseInLogoSquare(adjMouseX, adjMouseY));
    if (mousePressed && !mouseFirstPressed) {
        mouseFirstPressed = true;
        if (isDragClick(adjMouseX, adjMouseY)) {
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

boolean isDragClick(float adjMouseX, float adjMouseY) {
    return mouseInLogoSquare(adjMouseX, adjMouseY) || mouseInDragCircle(adjMouseX, adjMouseY);
}

boolean mouseInLogoSquare(float adjMouseX, float adjMouseY) {
    // println("logo:        (" + logoX + ", " + logoY + ")");
    // println("logoZ:       " + -1.f * halfZ);
    // println("logo bounds: ([" + (logoX - logoZ) + ", " + (logoX + logoZ) + "], [" + (logoY - logoZ) + ", " + (logoY + logoZ) + "])");

    float halfZ = logoZ / 2;

    float mouseVecX = adjMouseX - logoX;
    float mouseVecY = adjMouseY - logoY;

    float oppLogoRotRads = - logoRotation;
    // println("logoRotation: " + logoRotation);

    float rotMouseX = cos(oppLogoRotRads) * mouseVecX - sin(oppLogoRotRads) * mouseVecY;
    float rotMouseY = sin(oppLogoRotRads) * mouseVecX + cos(oppLogoRotRads) * mouseVecY;

    return rotMouseX >= - 1.f * halfZ && rotMouseX <= halfZ && rotMouseY >= - 1.f * halfZ && rotMouseY <= halfZ;
}

boolean mouseInDragCircle(float adjMouseX, float adjMouseY) {
    return dist(adjMouseX, adjMouseY, logoX, logoY) < dragCircleRadius;
}

void visualizeMousePoint() {
    float adjMouseX = mouseX - (width / 2);
    float adjMouseY = mouseY - (height / 2);

    float halfZ = logoZ / 2;

    float mouseVecX = adjMouseX - logoX;
    float mouseVecY = adjMouseY - logoY;

    float oppLogoRotRads = - logoRotation;

    float rotMouseX = cos(oppLogoRotRads) * mouseVecX - sin(oppLogoRotRads) * mouseVecY;
    float rotMouseY = sin(oppLogoRotRads) * mouseVecX + cos(oppLogoRotRads) * mouseVecY;
    circle(width / 2 + logoX + rotMouseX, height / 2 + logoY + rotMouseY, 5);

    println("rot mouse: (" + rotMouseX + ", " + rotMouseY + ")");
    println("logoZ:     [" + ( - 1.f * halfZ) + ", " + halfZ + "]");

    pushMatrix();
    translate(width / 2, height / 2); //center the drawing coordinates to the center of the screen
    translate(logoX, logoY);
    // rotate(logoRotation);
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
    mouseRotandSize = false;

    if (mouseMove) {
        mouseMove = false;
        if (userDone == false && !checkForSuccess())
            errorCount++;

        trialIndex++; //and move on to next trial

        if (trialIndex == trialCount && userDone == false)
        {
            userDone = true;
            finishTime = millis();
        }

        return;
    }

    logoRotation -= c_angle - currAngle;
    c_angle = 0;
    currAngle = 0;
}

void mouseDragged() {
    if (mouseRotandSize) {
        currAngle = atan2(mouseY - height / 2 - logoY, mouseX - width / 2 - logoX);

        logoZ += round(dist(mouseX, mouseY, logoX + width / 2, logoY + height / 2) - dist(refX, refY, logoX + width / 2, logoY + height / 2));
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
