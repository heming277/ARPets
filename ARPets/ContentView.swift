//
//  ContentView.swift
//  ARPets
//
//  Created by Heming Liu on 2023-12-04.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @State private var takeSnapshot = false
    
    var body: some View {
        ZStack {
            ARViewContainer(takeSnapshot: $takeSnapshot)
                .edgesIgnoringSafeArea(.all)
                .onChange(of: takeSnapshot) {
                    // Code to handle the snapshot
                    // Reset the state to `false` inside a DispatchQueue.main.async block
                    DispatchQueue.main.async {
                        self.takeSnapshot = false
                    }
                }

            // Button to take a snapshot
            VStack {
                Spacer()
                Button(action: {
                    self.takeSnapshot = true
                }) {
                    Text("Take Photo")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var takeSnapshot: Bool
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        // Set the session delegate
        arView.session.delegate = context.coordinator

        // Attempt to load the JCUBE_maneki.usdz file
        let filename = "JCUBE_Maneki"
        if let modelEntity = try? ModelEntity.load(named: filename) {
            // Create an anchor with a horizontal plane
            let anchor = AnchorEntity(.camera)
            
            let position = SIMD3<Float>(x: 0.0, y: 0.0, z: -0.5) // 1 meter in front of the camera
            modelEntity.position = position
            // Add modelEntity to the anchor
            anchor.addChild(modelEntity)
            // Add the anchor to the scene
            arView.scene.anchors.append(anchor)
        } else {
            print("Error: Unable to load model entity")
        }
        context.coordinator.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if self.takeSnapshot {
            context.coordinator.takeSnapshot(uiView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject,ARSessionDelegate{
        var parent: ARViewContainer
        var petAnchor: AnchorEntity?
        var arView: ARView?
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let cameraTransform = session.currentFrame?.camera.transform else { return }
            
            if petAnchor == nil {
                // Create the anchor and model entity only once
                petAnchor = AnchorEntity(world: cameraTransform)
                let filename = "JCUBE_Maneki"
                if let modelEntity = try? ModelEntity.load(named: filename) {
                    petAnchor?.addChild(modelEntity)
                }
                if let arView = session.delegate as? ARView {
                    arView.scene.addAnchor(petAnchor!)
                }
            } else {
                // Update the pet anchor's position relative to the camera continuously
                let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
                let petPositionOffset = SIMD3<Float>(0, 0, -1) // 1 meter in front of the camera
                let newPetPosition = cameraPosition + petPositionOffset
                // Use a smooth transition to update the pet's position
                petAnchor?.move(to: Transform(scale: .one, rotation: petAnchor!.orientation, translation: newPetPosition), relativeTo: nil, duration: 0.1, timingFunction: .linear)
            }
        }
        
        func takeSnapshot(_ arView: ARView) {
            arView.snapshot(saveToHDR: false) { (image) in
                guard let image = image else { return }
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.saveError), nil)
            }
        }
        
        @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            if let error = error {
                print("Error saving photo: \(error.localizedDescription)")
            } else {
                print("Photo saved successfully")
            }
        }
    }
    
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

