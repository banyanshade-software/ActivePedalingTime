using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.ActivityRecording;
using Toybox.Application;
using Toybox.FitContributor;
using Toybox.Lang;

  // FSM states
enum  {
    IDLE,
    STARTING,
    CYCLING,
    SLOWING_DOWN
 }

class ActivePedalingTimerView extends WatchUi.SimpleDataField {
    
   
    private var state = IDLE;

    // parameters (set at initialization, value are hardcoded for now)
    private var mStopDelay;
    private var mStartDelay;
    private var mSpeedThreshold;

    // Variables pour tracker le temps de pédalage actif
    private var mStartPedalingTime;
    private var mLastUpdateTime;
    private var mBeginStopTime;
    //private var mBeginStartTime; // replaced by mMovingStartTime 
     
    //private var mIsMoving;
    //private var mLastSpeed;
    private var mMovingStartTime;
  
    //private var mSlowStartTime;
    private var fitField;

  

    function getLabel() {
        // Récupère la chaîne selon la langue du système
        return WatchUi.loadResource(Rez.Strings.fldname);
    }


    function initialize() {
        SimpleDataField.initialize();
        label = getLabel();
        

        mLastUpdateTime = null;
        mStartPedalingTime = null;
        mBeginStopTime = null;
        mMovingStartTime = null;
        //parameters
        mStopDelay = 15*1000; // 15 seconds delay before stopping
        mStartDelay = 3*1000; // 3 seconds delay before starting
        mSpeedThreshold = 1.0; // Seuil de vitesse en m/s (3.6 km/h)

        //mIsMoving = false;
        //mLastSpeed = 0;
        mMovingStartTime = null;
        //mSlowStartTime = null;
    }


    // Appelé quand l'activité démarre
    //function onTimerStart() {
    //    mLastUpdateTime = System.getTimer();
    //}

    // Appelé quand l'activité s'arrête
    /*function onTimerStop() {
        // Si on était en mouvement, ajouter le temps écoulé
        if (mIsMoving && mMovingStartTime != null) {
            var currentTime = System.getTimer();
            var endTime = (mSlowStartTime != null) ? mSlowStartTime : currentTime;
            mActivePedalingTime += (endTime - mMovingStartTime);
        }
        mIsMoving = false;
        mMovingStartTime = null;
        mSlowStartTime = null;
    }*/

    // Appelé quand l'activité est en pause
    /*
    function onTimerPause() {
        // Si on était en mouvement, ajouter le temps écoulé
        if (mIsMoving && mMovingStartTime != null) {
            var currentTime = System.getTimer();
            var endTime = (mSlowStartTime != null) ? mSlowStartTime : currentTime;
            mActivePedalingTime += (endTime - mMovingStartTime);
        }
        mIsMoving = false;
        mMovingStartTime = null;
        mSlowStartTime = null;
    }*/

    
    /*
    // Appelé quand l'activité reprend après une pause
    function onTimerResume() {
        updateFit();
        mActivePedalingTime = 0; // reset active time
        mLastUpdateTime = System.getTimer();
    }
    */

    function updateFit(v) as Void {
        fitField.setData(v);
    }
    
    // called periodically to compute the data field value
    function compute(info) {
        var currentTime = System.getTimer();
        
        if (mLastUpdateTime == null) {
            mLastUpdateTime = currentTime;
            return "---";
        }

        // Check current speed
        var currentSpeed = 0;
        if (info has :currentSpeed && info.currentSpeed != null) {
            currentSpeed = info.currentSpeed;
        } else {
            return "---"; // no speed data available
        }
        var isAboveThreshold = (currentSpeed > mSpeedThreshold);
        if (isAboveThreshold) {
           switch (state) {
                case IDLE:
                    mMovingStartTime = currentTime;
                    state = STARTING;
                    break;
                case STARTING:
                    if (currentTime >= mStartDelay + mMovingStartTime)  {
                        state = CYCLING;
                        mStartPedalingTime = currentTime - mStartDelay;
                        mMovingStartTime = null; // reset moving start time
                    }
                    break;
                case CYCLING:
                    // nothing to do, just continue counting
                    break;
                case SLOWING_DOWN:
                    state = CYCLING; // reset to cycling state
                    mBeginStopTime = null; 
                    break;
                default:
                    break;
           }
        } else {
            // bellow threshold
            switch (state) {
                case IDLE:
                    // nothing to do, already idle
                    break;
                case STARTING:
                    // if we were starting, reset to idle
                    state = IDLE;
                    mMovingStartTime = null; // reset moving start time
                    break;
                case CYCLING:
                    // if we were cycling, start slowing down
                    mBeginStopTime = currentTime;
                    state = SLOWING_DOWN;
                    break;

                case SLOWING_DOWN:
                    if (currentTime >= mStopDelay + mBeginStopTime) {
                        // if we were slowing down and the delay is over, reset to idle
                        state = IDLE;
                        mStartPedalingTime = null; // reset active pedaling time
                        mMovingStartTime = null; // reset moving start time
                        mBeginStopTime = null; // reset begin stop time
                    }
                    break;
                default:
                    break;
           }
        }
        
        mLastUpdateTime = currentTime;
        var pedalTime;
        if (mStartPedalingTime == null) {
            pedalTime = 0; // no active pedaling time
        } else {
            pedalTime = currentTime - mStartPedalingTime;
        }
        var str = formatTime(pedalTime, currentSpeed);
        return str;
    }

    // Formater le temps en chaîne
    function formatTime(timeInMillis, currentSpeed) {
        var totalSeconds = timeInMillis / 1000;
        var hours = Math.floor(totalSeconds / 3600);
        var minutes = Math.floor((totalSeconds % 3600) / 60);
        var seconds = Math.floor(totalSeconds % 60);
        var timeString;
        
        timeString = hours.format("%d") + ":" 
                         + minutes.format("%02d");
        if (true) { 
            timeString += ":"
                         + seconds.format("%02d")
                         + "/" + state.toString()
                         + "/" + currentSpeed.format("%0.2f") 
                         ;
        }
        return timeString;
    }


   
}

class ActivePedalingTimerApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new ActivePedalingTimerView()];
    }
}