//
//  Blur.swift
//  TabTapSample
//
//  Created by nagatadaisuke on 2017/09/03.
//  Copyright © 2017年 nagatadaisuke. All rights reserved.
//

import UIKit
import MetalPerformanceShaders
import MetalKit

protocol CommandBufferEncodable {
    init(device: MTLDevice)
    
    func encode(to commandBuffer: MTLCommandBuffer,
                sourceTexture: MTLTexture,
                destinationTexture: MTLTexture)
    
}

class GaussianBlur: CommandBufferEncodable {
    
    let gaussian: MPSImageGaussianBlur
    
    required init(device: MTLDevice) {
        
        gaussian = MPSImageGaussianBlur(device: device,
                                        sigma: 15.0)
        
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        gaussian.encode(commandBuffer: commandBuffer,
                        sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture)
        
    }
}
