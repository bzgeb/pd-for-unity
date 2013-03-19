using UnityEngine;
using System.Collections;

public class PDInit : MonoBehaviour {

	// Use this for initialization
	void Start () {
		PureData.initPd();
		PureData.openFile("basicsynth.pd");
		PureData.startAudio();
	}
}
