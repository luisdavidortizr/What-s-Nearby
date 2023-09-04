//
//  ViewController.swift
//  What's Nearby
//
//  Created by Luis David Ortiz on 31/08/23.
//

import UIKit
import SpriteKit
import ARKit

import CoreLocation
import GameplayKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSKView!
    
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    
    var sitesJSON: JSON!
    
    var userHeading = 0.0
    var headingStep = 0
    
    var sites = [UUID: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = AROrientationTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Sites functions
    
    func updateSites() {
        let urlString = "https://en.wikipedia.org/w/api.php?ggscoord=\(userLocation.coordinate.latitude)%7C\(userLocation.coordinate.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"
        guard let url = URL(string: urlString) else { return }
        
        if let data = try? Data(contentsOf: url) {
            sitesJSON = JSON(data)
            locationManager.startUpdatingHeading()
        }
    }
    
    func createSites() {
        // Hacer un bucle de todos los lugares del JSON
        for page in sitesJSON["query"]["pages"].dictionaryValue.values {
            // Ubicar latitud y longitud de los lugares
            let lat = page["coordinates"][0]["lat"].doubleValue
            let lon = page["coordinates"][0]["lon"].doubleValue
            let location = CLLocation(latitude: lat, longitude: lon)
            
            // Calcular la distancia y la dirección (azimut) desde el usuario hasta el lugar
            let distance = Float(userLocation.distance(from: location))
            let azimut = ARMath.direction(from: userLocation, to: location)
            
            // Sacar ángulo entre azimut y la dirección del usuario
            let angle = azimut - userHeading
            let angleRad = ARMath.deg2rad(angle)
            
            // Crear las matrices de rotación para posicionar horizontalmente el ancla
            let horizontalRotation = float4x4(SCNMatrix4MakeRotation(Float(angleRad), 1, 0, 0))
            
            // Crear la matriz para la rotación vertical basada en la distancia
            let verticalRotation = float4x4(SCNMatrix4MakeRotation(-0.3 + Float(distance/500), 0, 1, 0))
            
            // Multiplicar las matrices de rotación anteriores y multiplicarlas por la cámara ARKit
            let rotation = simd_mul(horizontalRotation, verticalRotation)
            
            // Crear una matriz identidad y moverla una cierta cantidad dependiendo de donde posicionar el objeto en profundidad
            guard let currentFrame = sceneView.session.currentFrame else { return }
            
            let rotation2 = simd_mul(currentFrame.camera.transform, rotation)
            
            // Posicionar el ancla y darle un identificador para localizarlo en escena
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -(distance / 500)
            
            let transform = simd_mul(rotation2, translation)
            
            let anchor = ARAnchor(transform: transform)
            sceneView.session.add(anchor: anchor)
            sites[anchor.identifier] = "\(page["title"].string ?? "Unknown Place") - \(distance)m"
        }
    }
}

extension ViewController: ARSKViewDelegate {
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        let labelNode = SKLabelNode(text: sites[anchor.identifier])
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        
        let newSize = labelNode.frame.size.applying(CGAffineTransform(scaleX: 1.1, y: 1.5))
        
        let backgroundNode = SKShapeNode(rectOf: newSize, cornerRadius: 10)
        let randomColor = UIColor(hue: CGFloat(GKRandomSource.sharedRandom().nextUniform()), saturation: 0.5, brightness: 0.4, alpha: 0.9)
        backgroundNode.fillColor = randomColor
        
        backgroundNode.strokeColor = randomColor.withAlphaComponent(1.0)
        backgroundNode.lineWidth = 2
        
        backgroundNode.addChild(labelNode)
        
        return backgroundNode
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        
        DispatchQueue.global().async {
            self.updateSites()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.headingStep += 1
            
            if self.headingStep < 2 { return }
            
            self.userHeading = newHeading.magneticHeading
            self.locationManager.stopUpdatingHeading()
            self.createSites()
        }
    }
}
