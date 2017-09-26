//
//  ViewController.swift
//  MetalBasicTessellation
//
//  Created by nagatadaisuke on 2017/09/04.
//  Copyright © 2017年 nagatadaisuke. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var edge: UILabel!
    @IBOutlet weak var inside: UILabel!
    var tessellationPipeline =  AAPLTessellationPipeline()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.mtkView.isPaused = true
        self.mtkView.enableSetNeedsDisplay = true
        self.mtkView.sampleCount = 4
        
        self.swipeMethod()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(true)
        
        self.tessellationPipeline = tessellationPipeline.initWithMTKView(mtkView:  self.mtkView )
        self.mtkView.draw()
        
    }
    
    @IBAction func triagleQuad(_ sender: UISegmentedControl)
    {
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.tessellationPipeline.patchType = MTLPatchType.triangle
            break;
        case 1:
            self.tessellationPipeline.patchType = MTLPatchType.quad
            break;
        case 2:
            self.tessellationPipeline.patchType = MTLPatchType.none
            break;
        default:
            break;
        }
        self.mtkView.draw()
        
    }
    
    @IBAction func segument(_ sender: UISwitch)
    {
        
        self.tessellationPipeline.wireframe = sender.isOn
        self.mtkView.draw()
        
    }
    
    @IBAction func sliderHorizon(_ sender: UISlider)
    {
        

        self.mtkView.clearColor =  MTLClearColorMake(Double(CGFloat(sender.value))/11, Double(CGFloat(sender.value))/22, Double(CGFloat(sender.value))/33, 1)
        self.edge.text = String(format: "%.01f", Float(sender.value))
        self.tessellationPipeline.edgeFactor = sender.value
        self.mtkView.draw()
        
    }
    
    @IBAction func insideHorizon(_ sender: UISlider)
    {
        

        self.mtkView.clearColor =  MTLClearColorMake(Double(CGFloat(sender.value))/33, Double(CGFloat(sender.value))/22, Double(CGFloat(sender.value))/11, 1)
        self.inside.text = String(format: "%.01f", Float(sender.value))
        self.tessellationPipeline.insideFactor = sender.value
        self.mtkView.draw()
        
    }
    
    private func swipeMethod()
    {
        let directions: [UISwipeGestureRecognizerDirection] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self,
                                                   action:#selector(handleSwipe(sender:)))
            
            gesture.direction = direction
            self.view.addGestureRecognizer(gesture)
        }
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer)
    {
        
        self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        self.mtkView.draw()
        
    }
}
