using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.ActivityRecording;
using Toybox.Application;
using Toybox.FitContributor;
using Toybox.Lang;

/*
class MyFitContributor extends Fit.FitContributorBase {
    
    function initialize() {
        FitContributorBase.initialize();
    }
    
    function getFieldDescriptors() {
        return [
            new Fit.FieldDescriptor(
                "my_custom_metric",
                0, // Field ID unique
                Fit.DATA_TYPE_FLOAT
            )
        ];
    }


    function onTimerLap() {
        // Appelé à chaque lap
    }
    
    function onTimerStart() {
        // Appelé au début de l'activité
    }
    
    function onTimerStop() {
        // Appelé à la fin de l'activité
    }
}
*/


class ActivePedalingTimerView extends WatchUi.SimpleDataField {
    
    // Variables pour tracker le temps de pédalage actif
    private var mActivePedalingTime;
    private var mLastUpdateTime;
    private var mIsMoving;
    private var mSpeedThreshold;
    private var mLastSpeed;
    private var mMovingStartTime;
    private var mStopDelay;
    private var mSlowStartTime;
    private var fitField;
    //private var lbl;

    function getLabel() {
        // Récupère la chaîne selon la langue du système
        return WatchUi.loadResource(Rez.Strings.fldname);
    }
    function initialize() {
        SimpleDataField.initialize();
        label = getLabel();
      
        /*fitField = createField(
            lbl,
            TACT_FIELD_ID,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"B"}
        );*/
    
        
        // Initialisation des variables
        mActivePedalingTime = 0;
        mLastUpdateTime = null;
        mIsMoving = false;
        mSpeedThreshold = 1.0; // Seuil de vitesse en m/s (3.6 km/h)
        mLastSpeed = 0;
        mMovingStartTime = null;
        mStopDelay = 15*1000; // 5 secondes de délai avant arrêt
        mSlowStartTime = null;
    }

    // Appelé quand l'activité démarre
    function onTimerStart() {
        mLastUpdateTime = System.getTimer();
    }

    // Appelé quand l'activité s'arrête
    function onTimerStop() {
        // Si on était en mouvement, ajouter le temps écoulé
        if (mIsMoving && mMovingStartTime != null) {
            var currentTime = System.getTimer();
            var endTime = (mSlowStartTime != null) ? mSlowStartTime : currentTime;
            mActivePedalingTime += (endTime - mMovingStartTime);
        }
        mIsMoving = false;
        mMovingStartTime = null;
        mSlowStartTime = null;
    }

    // Appelé quand l'activité est en pause
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
    }

    function updateFit() as Void {
        fitField.setData(mActivePedalingTime);
    }
    // Appelé quand l'activité reprend après une pause
    function onTimerResume() {
        updateFit();
        mActivePedalingTime = 0; // reset active time
        mLastUpdateTime = System.getTimer();
    }

    // Appelé à chaque mise à jour des données
    function compute(info) {
        var currentTime = System.getTimer();
        
        if (mLastUpdateTime == null) {
            mLastUpdateTime = currentTime;
            return "---";
        }

        // Récupérer la vitesse actuelle
        var currentSpeed = 0;
        if (info has :currentSpeed && info.currentSpeed != null) {
            currentSpeed = info.currentSpeed;
        }

        // Déterminer si on est au-dessus du seuil de vitesse
        var isAboveThreshold = (currentSpeed > mSpeedThreshold);
        //var wasMoving = mIsMoving;

        // Logique avec délai d'arrêt
        if (isAboveThreshold) {
            // On va assez vite
            if (!mIsMoving) {
                // On commence à bouger
                mIsMoving = true;
                mMovingStartTime = currentTime;
            }
            // Reset du délai d'arrêt
            mSlowStartTime = null;
            
        } else {
            // On est en dessous du seuil
            if (mIsMoving) {
                // On était en mouvement, commencer le décompte du délai
                if (mSlowStartTime == null) {
                    mSlowStartTime = currentTime;
                } else {
                    // Vérifier si le délai est écoulé
                    if (currentTime - mSlowStartTime >= mStopDelay) {
                        // Délai écoulé, arrêter le compteur
                        if (mMovingStartTime != null) {
                            // Ajouter le temps jusqu'au début du ralentissement
                            mActivePedalingTime += (mSlowStartTime - mMovingStartTime);
                        }
                        mIsMoving = false;
                        mMovingStartTime = null;
                        mSlowStartTime = null;
                    }
                }
            }
        }

        mLastSpeed = currentSpeed;
        mLastUpdateTime = currentTime;
        var str = formatTime(mActivePedalingTime);
        return str;
    }

    // Formater le temps en chaîne
    function formatTime(timeInMillis) {
        var totalSeconds = timeInMillis / 1000;
        var hours = Math.floor(totalSeconds / 3600);
        var minutes = Math.floor((totalSeconds % 3600) / 60);
        //var seconds = Math.floor(totalSeconds % 60);
        var timeString;
        
        timeString = hours.format("%d") + ":" + 
                         minutes.format("%02d");
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