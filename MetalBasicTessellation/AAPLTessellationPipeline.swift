//
//  AAPLTessellationPipeline.swift
//  MetalBasicTessellation
//
//  Created by nagatadaisuke on 2017/09/04.
//  Copyright © 2017年 nagatadaisuke. All rights reserved.
//
import Foundation
import UIKit
import MetalKit

class AAPLTessellationPipeline :NSObject,MTKViewDelegate{
    
    var device : MTLDevice!
    var commandQueue:MTLCommandQueue!
    var library : MTLLibrary!
    var computePipelineTriangle: MTLComputePipelineState!
    var computePipelineQuad : MTLComputePipelineState!
    var computePipelineQuadSecound : MTLComputePipelineState!
    var renderPipelineTriangle:MTLRenderPipelineState!
    var renderPipelineQuad: MTLRenderPipelineState!
    var renderPipelineQuadSecound: MTLRenderPipelineState!
    var tessellationFactorsBuffer:MTLBuffer!
    var controlPointsBufferTriangle:MTLBuffer!
    var controlPointsBufferQuad:MTLBuffer!
    var controlPointsBufferQuadSecound:MTLBuffer!
    var patchType : MTLPatchType!
    
    var wireframe = false
    var edgeFactor:Float!
    var insideFactor:Float!
    
    func initWithMTKView(mtkView: MTKView )->Self
    {
        
        wireframe = true
        patchType = MTLPatchType.triangle
        edgeFactor = 2.0
        insideFactor = 2.0
        
        if(!self.didSetupMetal()){
            
            return self
            
        }
        
        // Assign device and delegate to MTKView
        mtkView.device = device
        mtkView.delegate = self
        
        // Setup render pipelines
        if(!self.didSetupComputePipelines()){
            
            return self
            
        }
        
        // Setup render pipelines
        if(!self.didSetupRenderPipelinesWithMTKView(view:mtkView)) {
            
            return self
            
        }
        
        // Setup Buffers
        setUpBuffers()
        
        return self
        
    }
    
    func didSetupMetal()->Bool
    {
        
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        library = device.makeDefaultLibrary()
        
        return true
        
    }

    func didSetupComputePipelines()->Bool
    {
        let kernelFunctionTriangle = library.makeFunction(name: "tessellation_kernel_triangle")
        
        do{
            
            computePipelineTriangle = try device.makeComputePipelineState(function: kernelFunctionTriangle!)
            
        }catch{}
        
        let kernelFunctionQuad = library.makeFunction(name: "tessellation_kernel_quad")
        
        do{
            
            computePipelineQuad = try device.makeComputePipelineState(function: kernelFunctionQuad!)
            
        }catch{}
        
        let kernelFunctionQuadSwcound = library.makeFunction(name: "tessellation_kernel_quad")
        
        do{
            
            computePipelineQuadSecound = try device.makeComputePipelineState(function: kernelFunctionQuadSwcound!)
            
        }catch{}
        
        return true
        
    }
    
    func didSetupRenderPipelinesWithMTKView(view:MTKView)->Bool
    {

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = MTLVertexFormat.float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.perPatchControlPoint
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stride = 16
        
        // Create a reusable render pipeline descriptor
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.sampleCount = view.sampleCount
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "tessellation_fragment")
        
        // Configure common tessellation properties
        renderPipelineDescriptor.isTessellationFactorScaleEnabled = false
        renderPipelineDescriptor.tessellationFactorFormat = MTLTessellationFactorFormat.half
        renderPipelineDescriptor.tessellationControlPointIndexType = MTLTessellationControlPointIndexType.none
        renderPipelineDescriptor.tessellationFactorStepFunction = MTLTessellationFactorStepFunction.constant
        renderPipelineDescriptor.tessellationOutputWindingOrder = MTLWinding.clockwise
        renderPipelineDescriptor.tessellationPartitionMode = MTLTessellationPartitionMode.fractionalEven
        
        // In iOS, the maximum tessellation factor is 16
        renderPipelineDescriptor.maxTessellationFactor = 16
        
        // Create render pipeline for triangle-based tessellation
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "tessellation_vertex_triangle")
        
        do{
            
            renderPipelineTriangle = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
            
        }catch{}
        
        // Create render pipeline for quad-based tessellation
        renderPipelineDescriptor.vertexFunction =  library.makeFunction(name: "tessellation_vertex_quad")
        
        do{
            
            renderPipelineQuad = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
            
        }catch{}

        
        // Create render pipeline for quad-based tessellation
        renderPipelineDescriptor.vertexFunction =  library.makeFunction(name: "tessellation_vertex_quadSecound")
        
        do{
            
            renderPipelineQuadSecound = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
            
        }catch{}
        
        return true
    }
    
    func setUpBuffers()
    {
        //validateComputeFunctionArguments length - offset must be >= 12
        tessellationFactorsBuffer = device.makeBuffer(length: 12,
                                                      options: MTLResourceOptions.storageModePrivate)
        
        tessellationFactorsBuffer.label = "Tessellation Factors"
        var controlPointsBufferOptions = MTLResourceOptions()
        controlPointsBufferOptions = .storageModeShared
        
        let controlPointPositionsTriangle : Array<Float> =  {
            
            [
               -0.8, -0.8, 0.0, 1.0,  // upper-left
                0.0,  0.8, 0.0, 1.0,  // upper-right
                0.8, -0.8, 0.0, 1.0,  // lower-right
                
            ]
            
        }()
        //Animation is set from 88.
        controlPointsBufferTriangle = device.makeBuffer(bytes:controlPointPositionsTriangle,
                                                        length:  MemoryLayout.size(ofValue: controlPointPositionsTriangle)*11,
                                                        options: controlPointsBufferOptions)
        
        controlPointsBufferTriangle.label = "Control Points Triangle"
        
        let controlPointPositionsQuad  : Array<Float>  =  {
            
            [
               -0.8,  0.8, 0.0, 1.0,   // upper-left
                0.8,  0.8, 0.0, 1.0,   // upper-right
                0.8, -0.8, 0.0, 1.0,   // lower-right
               -0.8, -0.8, 0.0, 1.0,   // lower-left
            ]
            
        }()
        //Animation is set from 88.
        controlPointsBufferQuad = device.makeBuffer(bytes:controlPointPositionsQuad,
                                                    length: MemoryLayout.size(ofValue: controlPointPositionsQuad)*11,
                                                    options: controlPointsBufferOptions)
        
        controlPointsBufferQuad.label = "Control Points Quad"
        
        let controlPointPositionsQuadSecound  : Array<Float>  =  {
            
            [
               -0.8,  0.8, 0.0, 1.0,   // upper-left
                0.8,  0.8, 0.0, 1.0,   // upper-right
                0.8, -0.8, 0.0, 1.0,   // lower-right
               -0.8, -0.8, 0.0, 1.0,   // lower-left
            ]
            
        }()
        
        controlPointsBufferQuadSecound = device.makeBuffer(bytes:controlPointPositionsQuadSecound,
                                                    length: MemoryLayout.size(ofValue: controlPointPositionsQuad)*11,
                                                    options: controlPointsBufferOptions)
        
        controlPointsBufferQuadSecound.label = "Control Points Quad"
        
    }
    
    func computeTessellationFactorsWithCommandBuffer(commandBuffer:MTLCommandBuffer)
    {
        // Create a compute command encoder
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        computeCommandEncoder?.label = "Compute Command Encoder"
        computeCommandEncoder?.pushDebugGroup("Compute Tessellation Factors")
        
        if self.patchType == MTLPatchType.triangle {
            
            computeCommandEncoder?.setComputePipelineState(computePipelineTriangle)
            
        } else if self.patchType == MTLPatchType.quad{
            
            computeCommandEncoder?.setComputePipelineState(computePipelineQuad)
            
        }else if self.patchType == MTLPatchType.none{
            
            computeCommandEncoder?.setComputePipelineState(computePipelineQuadSecound)
            
        }
        
        computeCommandEncoder?.setBytes(&edgeFactor, length: MemoryLayout.size(ofValue:1), index: 0)
        computeCommandEncoder?.setBytes(&insideFactor, length: MemoryLayout.size(ofValue:1), index: 1)
        computeCommandEncoder?.setBuffer(tessellationFactorsBuffer, offset: 0, index: 2)
        
        // Bind the user-selected edge and inside factor values to the compute kernel
        computeCommandEncoder?.dispatchThreadgroups(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        
        // All compute commands have been encoded
        computeCommandEncoder?.popDebugGroup()
        computeCommandEncoder?.endEncoding()
    }
    
    func tessellateAndRenderInMTKView(view:MTKView,withCommandBuffer:MTLCommandBuffer)
    {
        
        // Obtain a renderPassDescriptor generated from the view's drawable
        let renderPassDescriptor = view.currentRenderPassDescriptor
        let renderCommandEncoder = withCommandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
        
        if renderPassDescriptor != nil {
            
            renderCommandEncoder?.label = "Render Command Encoder"
            
            // Begin encoding render commands, including commands for the tessellator
            renderCommandEncoder?.pushDebugGroup("Tessellate and Render")
            
        }
        
        // Set the correct render pipeline and bind the correct control points buffer
        if(self.patchType == MTLPatchType.triangle) {
            
            renderCommandEncoder?.setRenderPipelineState(renderPipelineTriangle)
            renderCommandEncoder?.setVertexBuffer(controlPointsBufferTriangle, offset: 0, index: 0)
            
        }else if self.patchType == MTLPatchType.quad {
            
            renderCommandEncoder?.setRenderPipelineState(renderPipelineQuad)
            renderCommandEncoder?.setVertexBuffer(controlPointsBufferQuad, offset: 0, index: 0)
            
        }else if self.patchType == MTLPatchType.none {
            
            renderCommandEncoder?.setRenderPipelineState(renderPipelineQuadSecound)
            renderCommandEncoder?.setVertexBuffer(controlPointsBufferQuadSecound, offset: 0, index: 0)
            
        }
        
        // Enable/Disable wireframe mode
        if wireframe == true{
            
            renderCommandEncoder?.setTriangleFillMode(MTLTriangleFillMode.lines)
            
        }
        
        // Encode tessellation-specific commands
        renderCommandEncoder?.setTessellationFactorBuffer(tessellationFactorsBuffer, offset: 0, instanceStride: 0)
        let patchControlPoints = self.patchType == MTLPatchType.triangle ? 3: 4
        
        renderCommandEncoder?.drawPatches(numberOfPatchControlPoints: patchControlPoints,
                                          patchStart: 0,
                                          patchCount: 1,
                                          patchIndexBuffer: nil,
                                          patchIndexBufferOffset: 0,
                                          instanceCount: 1,
                                          baseInstance: 0)
        
        // All render commands have been encoded
        renderCommandEncoder?.popDebugGroup()
        renderCommandEncoder?.endEncoding()
        
        // Schedule a present once the drawable has been completely rendered to
        withCommandBuffer.present(view.currentDrawable!)
        
    }
    
    //#pragma mark Compute/Render methods
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView)
    {
        autoreleasepool{
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            self.computeTessellationFactorsWithCommandBuffer(commandBuffer: commandBuffer!)
            self.tessellateAndRenderInMTKView(view: view, withCommandBuffer: commandBuffer!)
            
            // Finalize tessellation pass and commit the command buffer to the GPU
            commandBuffer?.commit()
            
        }
    }
}
