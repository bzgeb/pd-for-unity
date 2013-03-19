using UnityEngine;
using System.Collections;

public class PDInit : MonoBehaviour {

	// Use this for initialization
	void Start () {
		PureData.initPd();
		PureData.openFile("basicsynth.pd");
		PureData.startAudio();
	}
	
	 void Update() {
	 	if ( Input.touchCount > 0 ) {
	 		PureData.sendFloat(Random.Range(40, 127), "note");
	 	}
	 }
}
