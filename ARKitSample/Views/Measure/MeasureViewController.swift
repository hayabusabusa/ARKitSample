//
//  MeasureViewController.swift
//  ARKitSample
//
//  Created by Yamada Shunya on 2019/12/25.
//  Copyright © 2019 Shunya Yamada. All rights reserved.
//

import UIKit
import ARKit

final class MeasureViewController: BaseARViewController {
    
    // MARK: IBOutlet
    
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var sceneView: ARSCNView!
    @IBOutlet private weak var measureLabel: UILabel!
    @IBOutlet private weak var measureButton: UIButton!
    
    // MARK: Properties
    
    private var startSphereNode: SCNNode?
    private var endSphereNode: SCNNode?
    private var lineNode: SCNNode?
    
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
    
    @IBAction func onTapMeasureButton(_ sender: Any) {
        measuring()
    }
}

// MARK: - Setup

extension MeasureViewController {
    
    private func setupViews() {
        let arSession = ARSession()
        sceneView.session = arSession
        sceneView.delegate = self
        //sceneView.showsStatistics = true
        sceneView.debugOptions = .showFeaturePoints
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

// MARK: - ARSceneView

extension MeasureViewController {
    
    private func measuring() {
        // 画面中心の3次元座標を取得
        guard let centerPosition = getCenterPosition() else { return }
        
        // 始点を設定済みかどうかを確認
        if let _ = startSphereNode {
            endSphereNode = addSphereNode(at: centerPosition, color: .systemOrange)
            measureButton.isEnabled = false
        } else {
            startSphereNode = addSphereNode(at: centerPosition, color: .systemOrange)
            measureButton.setTitle("終点を設定", for: .normal)
        }
    }
    
    private func getCenterPosition() -> SCNVector3? {
        // Types が肝かも
        // .featurePoint だと意図しない座標( 思ったよりも手前の座標とか )
        guard let centerPosition = sceneView.hitTest(sceneView.center, types: .existingPlane).first else { return nil }
        return SCNVector3(centerPosition.worldTransform.columns.3.x,
                          centerPosition.worldTransform.columns.3.y,
                          centerPosition.worldTransform.columns.3.z)
    }
    
    private func addSphereNode(at position: SCNVector3, color: UIColor) -> SCNNode {
        let node = SCNNode.sphereNode(color: color)
        sceneView.scene.rootNode.addChildNode(node)
        node.position = position
        return node
    }
    
    private func calcDistance(start: SCNVector3, end: SCNVector3) -> Float {
        let difference = SCNVector3Make(end.x - start.x,
                                        end.y - start.y,
                                        end.z - start.z)
        return sqrtf((difference.x * difference.x) + (difference.y * difference.y) + (difference.z * difference.z))
    }
}

// MARK: - ARSCNView delegate

extension MeasureViewController: ARSCNViewDelegate {
    
    private func updateLineNode(from: SCNNode, to: SCNVector3, length: Float) {
        if let lineNode = lineNode {
            lineNode.removeFromParentNode()
            self.lineNode = nil
        }
        let lineNode = SCNNode.lineNode(length: CGFloat(length), color: .systemYellow)
        self.lineNode = lineNode
        from.addChildNode(lineNode)
        lineNode.position = SCNVector3Make(0, 0, -length / 2)
        from.look(at: to)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let startSphereNode = startSphereNode,
            endSphereNode == nil else { return } // Only measuring
        
        // この辺はほとんどバックグラウンドのスレッドで実行されるので注意
        DispatchQueue.main.async {
            guard let centerPosition = self.getCenterPosition() else { return }
            let distance = self.calcDistance(start: startSphereNode.position, end: centerPosition)
            self.updateLineNode(from: startSphereNode, to: centerPosition, length: distance)
            self.measureLabel.text = String(format: "%.2fm", distance)
        }
    }
}
