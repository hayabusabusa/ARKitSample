//
//  Draw3DModelViewController.swift
//  ARKitSample
//
//  Created by Yamada Shunya on 2019/12/25.
//  Copyright © 2019 Shunya Yamada. All rights reserved.
//

import UIKit
import ARKit

final class Draw3DModelViewController: BaseARViewController {
    
    // MARK: IBOutlet
    
    @IBOutlet private weak var sceneView: ARSCNView!
    @IBOutlet private weak var closeButton: UIButton!
    
    // MARK: Properties
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseSession()
    }
    
    // MARK: Tap event
    
    @objc
    private func onTapSceneView(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3,
                       animations: { self.closeButton.alpha = self.closeButton.isUserInteractionEnabled ? 0 : 1 }) { _ in
                        self.closeButton.isUserInteractionEnabled.toggle()
        }
    }
    
    @IBAction
    private func onTapCloseButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Setup

extension Draw3DModelViewController {
    
    private func setupViews() {
        // Create session
        let arSession = ARSession()
        sceneView.session = arSession
        sceneView.delegate = self
        sceneView.showsStatistics = true
        //sceneView.debugOptions = .showFeaturePoints
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapSceneView(_:))))
    }
    
    private func runSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: .stopTrackedRaycasts)
    }
    
    private func pauseSession() {
        sceneView.session.pause()
    }
}

// MARK: - ARSCNView delegate

extension Draw3DModelViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let scene = SCNScene(named: "Santa Claus/12165_Santa_Claus_v1_l2.scn"),
            let santaClausNode = scene.rootNode.childNode(withName: "12165_Santa_Claus_Head_12165_Santa_Claus_Head", recursively: true) else { fatalError() }
        
        // Setup scale
        let (min, max) = santaClausNode.boundingBox
        let width = CGFloat(max.x - min.x)
        let magnification = 0.1 / width
        santaClausNode.scale = SCNVector3(magnification, magnification, magnification)
        // Setup position
        santaClausNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        DispatchQueue.main.async {
            node.addChildNode(santaClausNode)
        }
    }
}
