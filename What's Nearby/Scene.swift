//
//  Scene.swift
//  What's Nearby
//
//  Created by Luis David Ortiz on 31/08/23.
//

import SpriteKit
import ARKit

class Scene: SKScene {
    
    override func didMove(to view: SKView) {
        // Setup your scene here
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Localizar el primer toque del conjunto de toques
        // Mirar si el toque cae dentro de la vista de AR
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        print("El toque ha sido en: (\(location.x), \(location.y))")
        
        // Buscar todos los nodos que han sido tocados por ese toque del usuario
        let hit = nodes(at: location)
        
        // Coger el primer sprite del array que devuelve el método anterior (si lo hay)
        if let sprite = hit.first {
            
        }
    }
}
