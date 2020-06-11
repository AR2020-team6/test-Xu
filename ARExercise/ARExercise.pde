import gab.opencv.*;
import processing.video.*;

final boolean MARKER_TRACKER_DEBUG = false;
final boolean BALL_DEBUG = false;

final boolean USE_SAMPLE_IMAGE = false;

// We've found that some Windows build-in cameras (e.g. Microsoft Surface)
// cannot work with processing.video.Capture.*.
// Instead we use DirectShow Library to launch these cameras.
final boolean USE_DIRECTSHOW = true;


// final double kMarkerSize = 0.036; // [m]
final double kMarkerSize = 0.024; // [m]

Capture cap;
DCapture dcap;
OpenCV opencv;

// Variables for Homework 6 (2020/6/10)
// **************************************************************
float fov = 45; // for camera capture

// Marker codes to draw snowmans
// final int[] towardsList = {0x1228, 0x0690};
// int towards = 0x1228; // the target marker that the ball flies towards
// 球传给谁
int towardscnt = 0;   // if ball reached, +1 to change the target

// ※靶位
// final int[] towardsList = {0x005A, 0x0272};
final int[] towardsList = {0x1C44, 0x0272, 0x005A};
// int towards = 0x005A;
int towards = 0x1C44;


final float GA = 9.80665;

PVector snowmanLookVector;
PVector ballPos;
float ballAngle = 45;
float ballspeed = 0;

PShape UFOModel;
PShape butterflyModel;
float UFORotateSpeed = 3;
float UFOHight = -0.01;
float UFOHightSpeed = -0.0001; 
float UFOPositionX = 0;
float UFOPositionY = 0;
float UFOMoveSpeed = 0.1;
int UFOTotalFrame = 360;
int UFOframeCnt = 0;

PShape blueEyes;
boolean fire = false;

// 帧率越小, 小球运动越快
int ballTotalFrame = 10;
final float snowmanSize = 0.020;
int frameCnt = 0;

HashMap<Integer, PMatrix3D> markerPoseMap;

MarkerTracker markerTracker;
PImage img;

KeyState keyState;

void selectCamera() {
  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default");
    cap = new Capture(this, 640, 480);
  } else if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);

    // The camera can be initialized directly using an element
    // from the array returned by list():
    //cap = new Capture(this, cameras[5]);

    // Or, the settings can be defined based on the text in the list
    cap = new Capture(this, 1280, 720, "USB2.0 HD UVC WebCam", 30);
  }
}

void settings() {
  if (USE_SAMPLE_IMAGE) {
    // Here we introduced a new test image in Lecture 6 (20/05/27)
    size(1280, 720, P3D);
    opencv = new OpenCV(this, "./marker_test2.jpg");
    // size(1000, 730, P3D);
    // opencv = new OpenCV(this, "./marker_test.jpg");
  } else {
    if (USE_DIRECTSHOW) {
      dcap = new DCapture();
      size(dcap.width, dcap.height, P3D);
      opencv = new OpenCV(this, dcap.width, dcap.height);
    } else {
      selectCamera();
      size(cap.width, cap.height, P3D);
      opencv = new OpenCV(this, cap.width, cap.height);
    }
  }
}

void setup() {
  background(0);
  smooth();
  // frameRate(10);

  markerTracker = new MarkerTracker(kMarkerSize);

  if (!USE_DIRECTSHOW)
    cap.start();

  // Added on Homework 6 (2020/6/10)
  // Align the camera coordinate system with the world coordinate system
  // (cf. drawSnowman.pde)
  PMatrix3D cameraMat = ((PGraphicsOpenGL)g).camera;
  cameraMat.reset();

  keyState = new KeyState();

  // Added on Homework 6 (2020/6/10)
  ballPos = new PVector();  // ball position
  markerPoseMap = new HashMap<Integer, PMatrix3D>();  // hashmap (code, pose)
  
  UFOModel = loadShape("UFO/UFO.obj");
  UFOModel.scale(0.000025);
  UFOModel.rotateX(PI);
  
  butterflyModel = loadShape("butterfly2/butterfly2.obj");
  butterflyModel.scale(0.00005);
  butterflyModel.rotateX(PI);

  blueEyes = loadShape("BlueEyes/BlueEyes.obj");
  blueEyes.scale(0.0005);
  blueEyes.rotateX(3*PI/2);
}


void draw() {
  ArrayList<Marker> markers = new ArrayList<Marker>();
  markerPoseMap.clear();

  if (!USE_SAMPLE_IMAGE) {
    if (USE_DIRECTSHOW) {
      img = dcap.updateImage();
      opencv.loadImage(img);
    } else {
      if (cap.width <= 0 || cap.height <= 0) {
        println("Incorrect capture data. continue");
        return;
      }
      opencv.loadImage(cap);
    }
  }


  // Your Code for Homework 6 (20/06/03) - Start
  // **********************************************

  // use orthographic camera to draw images and debug lines
  // translate matrix to image center
  ortho();
  pushMatrix();
    translate(-width/2, -height/2,-(height/2)/tan(radians(fov)));
    markerTracker.findMarker(markers);
  popMatrix();

  // use perspective camera
  perspective(radians(fov), float(width)/float(height), 0.01, 1000.0);

  // setup light
  // (cf. drawSnowman.pde)
  ambientLight(180, 180, 180);
  directionalLight(180, 150, 120, 0, 1, 0);
  lights();

  // for each marker, put (code, matrix) on hashmap 
  for (int i = 0; i < markers.size(); i++) {
    Marker m = markers.get(i);
    markerPoseMap.put(m.code, m.pose);
  }
  
  // Adjusting the rotation
  if (UFOframeCnt >= UFOTotalFrame){
    UFOframeCnt = 0;
  }
  
  // Adjusting the height
  if (UFOHight < -0.011 || UFOHight > -0.009){
    UFOHightSpeed = -UFOHightSpeed;
  }
  
  // UFO Position
  PMatrix3D posit = markerPoseMap.get(towardsList[0]);
  // Butterfly Position
  PMatrix3D posit2 = markerPoseMap.get(towardsList[1]);
  // BlueEyes Position
  PMatrix3D posit3 = markerPoseMap.get(towardsList[2]);

  // UFO Model
  pushMatrix();

    if (posit != null){
      applyMatrix(posit);

      if (posit3 != null){
        PVector MoveVector = new PVector();
        MoveVector.x = posit3.m03 - UFOPositionX;
        MoveVector.y = posit3.m13 - UFOPositionY;
        // float MoveVectorLen = MoveVector.mag();

        UFOPositionX += MoveVector.x*UFOMoveSpeed;
        UFOPositionY += MoveVector.y*UFOMoveSpeed;
        println("Test:",MoveVector.x, MoveVector.y);

      }
    
      pushMatrix();
        translate(UFOPositionX, UFOPositionY, UFOHight);  // 高さ
        // Rotate
        if (UFOframeCnt < UFOTotalFrame){
          rotateZ(UFOframeCnt*UFORotateSpeed/UFOTotalFrame*2*PI);
          shape(UFOModel);
          UFOframeCnt += UFORotateSpeed;
        }
        UFOHight += UFOHightSpeed;
      
      popMatrix();
    }
  popMatrix();
  

  // Butterfly Model
  pushMatrix();  

    if (posit2 != null){
      applyMatrix(posit2);
      shape(butterflyModel);
    }
  popMatrix();
  
  

  // BlueEyes Model
  pushMatrix();
    
    if (posit3 != null){
      applyMatrix(posit3);
      shape(blueEyes);
      // Dragon fire
      if (fire){
        // fire
      }
    }

  popMatrix();


  noLights();
  keyState.getKeyEvent();

  System.gc();
}

void captureEvent(Capture c) {
  PGraphics3D g;
  if (!USE_DIRECTSHOW && c.available())
      c.read();
}

float rotateToMarker(PMatrix3D thisMarker, PMatrix3D lookAtMarker, int markernumber) {
  PVector relativeVector = new PVector();
  relativeVector.x = lookAtMarker.m03 - thisMarker.m03;
  relativeVector.y = lookAtMarker.m13 - thisMarker.m13;
  relativeVector.z = lookAtMarker.m23 - thisMarker.m23;
  float relativeLen = relativeVector.mag();

  relativeVector.normalize();

  float[] defaultLook = {1, 0, 0, 0};
  snowmanLookVector = new PVector();
  snowmanLookVector.x = thisMarker.m00 * defaultLook[0];
  snowmanLookVector.y = thisMarker.m10 * defaultLook[0];
  snowmanLookVector.z = thisMarker.m20 * defaultLook[0];

  snowmanLookVector.normalize();

  float angle = PVector.angleBetween(relativeVector, snowmanLookVector);
  if (relativeVector.x * snowmanLookVector.y - relativeVector.y * snowmanLookVector.x < 0)
    angle *= -1;

  return angle;
}

