// sample code for keyevents
// currently we manipulate binary thresholds of the marker tracker

class KeyState {
  HashMap<Integer, Boolean> key;

  KeyState() {
    key = new HashMap<Integer, Boolean>();

    key.put(RIGHT, false);
    key.put(LEFT,  false);
    key.put(UP,    false);
    key.put(DOWN,  false);
    key.put(90, false);  // key z
    key.put(88, false);  // key x
    key.put(87, false);  // key w
    key.put(83, false);  // key s
    key.put(65, false);  // key a
    key.put(68, false);  // key d
  }

  void putState(int code, boolean state) {
    key.put(code, state);
  }

  boolean getState(int code) {
    return key.get(code);
  }

  void getKeyEvent() {
      down_key=false;
      up_key=false;
      right_key=false;
      left_key=false;
    if (getState(LEFT)) {
      left_key=true;
      right_key=false;
      up_key=false;
    
      //markerTracker.thresh -= 1;
    }

    if (getState(RIGHT)) {
      right_key=true;

      left_key=false;
      up_key=false;

      //markerTracker.thresh += 1;
    }

    if (getState(UP)) {
      up_key=true;
      right_key=false;
      left_key=false;

      //markerTracker.bw_thresh += 1;
    }

    if (getState(DOWN)) {
      down_key=true;
      //markerTracker.bw_thresh -= 1;
    }

    if (getState(90)) {
      if (ballTotalFrame > 1) {
        ballTotalFrame -= 1;
      }
    }

    if (getState(88)) {
      ballTotalFrame += 1;
    }
    
    // w key
    if (getState(87)) {
      UFOPositionX += 0.002;
    }
    
    // s key
    if (getState(83)) {
      UFOPositionX -= 0.002;
    }
    
    // a key
    if (getState(65)) {
      UFOPositionY += 0.002;
    }
    
    // d key 
    if (getState(68)) {
      UFOPositionY -= 0.002;
    }


  }
}

void keyPressed() {
  keyState.putState(keyCode, true);
}

void keyReleased() {
  keyState.putState(keyCode, false);
}
