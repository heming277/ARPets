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
        
        // Enable horizontal plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration, options: [])
        
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
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var arView: ARView?
        var isPetAdded = false

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
            
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let arView = arView, !isPetAdded else { return } // Check if the pet has already been added
            
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal {
                    // Add the AR pet to the detected horizontal plane
                    let filename = "JCUBE_Maneki"
                    if let modelEntity = try? ModelEntity.load(named: filename) {
                        let anchorEntity = AnchorEntity(anchor: planeAnchor)
                        anchorEntity.addChild(modelEntity)
                        arView.scene.addAnchor(anchorEntity)
                        
                        isPetAdded = true // Set the flag to true after adding the pet
                        break // Break the loop
                    }
                }
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

