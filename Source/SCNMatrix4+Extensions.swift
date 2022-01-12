/*
* Copyright (c) 2013-2014 Kim Pedersen
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import SceneKit

public func * (left: SCNMatrix4, right: Float) -> SCNMatrix4 {
    return SCNMatrix4.init(m11: left.m11 * right, m12: left.m12 * right, m13: left.m13 * right, m14: left.m14 * right,
                           m21: left.m21 * right, m22: left.m22 * right, m23: left.m23 * right, m24: left.m24 * right,
                           m31: left.m31 * right, m32: left.m32 * right, m33: left.m33 * right, m34: left.m34 * right,
                           m41: left.m41 * right, m42: left.m42 * right, m43: left.m43 * right, m44: left.m44 * right)
}

public func SCNMatrix4Add( _ m1 : SCNMatrix4 , _ m2 : SCNMatrix4 ) -> SCNMatrix4 {
    
    return SCNMatrix4.init(m11: m1.m11 + m2.m11, m12: m1.m12 + m2.m12, m13: m1.m13 + m2.m13, m14: m1.m14 + m2.m14,
                           m21: m1.m21 + m2.m21, m22: m1.m22 + m2.m22, m23: m1.m23 + m2.m23, m24: m1.m24 + m2.m24,
                           m31: m1.m31 + m2.m31, m32: m1.m32 + m2.m32, m33: m1.m33 + m2.m33, m34: m1.m34 + m2.m34,
                           m41: m1.m41 + m2.m41, m42: m1.m42 + m2.m42, m43: m1.m43 + m2.m43, m44: m1.m44 + m2.m44)
    
}

public func SCNMatrix4Lerp( _ m1 : SCNMatrix4 , _ m2 : SCNMatrix4, _ v : Float ) -> SCNMatrix4 {
    
    return SCNMatrix4.init(m11: m1.m11 + (m2.m11-m1.m11)*v, m12: m1.m12 + (m2.m12-m1.m12)*v, m13: m1.m13 + (m2.m13-m1.m13)*v, m14: m1.m14 + (m2.m14-m1.m14)*v,
                           m21: m1.m21 + (m2.m21-m1.m21)*v, m22: m1.m22 + (m2.m22-m1.m22)*v, m23: m1.m23 + (m2.m23-m1.m23)*v, m24: m1.m24 + (m2.m24-m1.m24)*v,
                           m31: m1.m31 + (m2.m31-m1.m31)*v, m32: m1.m32 + (m2.m32-m1.m32)*v, m33: m1.m33 + (m2.m33-m1.m33)*v, m34: m1.m34 + (m2.m34-m1.m34)*v,
                           m41: m1.m41 + (m2.m41-m1.m41)*v, m42: m1.m42 + (m2.m42-m1.m42)*v, m43: m1.m43 + (m2.m43-m1.m43)*v, m44: m1.m44 + (m2.m44-m1.m44)*v)
    
}

public func SCNMatrix4GetAxesTransform( newX : SCNVector3 ,
                       newY : SCNVector3 ,
                       newZ : SCNVector3 ,
                       position : SCNVector3 = .zero ) -> SCNMatrix4 {
    
    let transform = SCNMatrix4.init(m11: newX.x, m12: newX.y, m13: newX.z, m14: 0,
                                    m21: newY.x, m22: newY.y, m23: newY.z, m24: 0,
                                    m31: newZ.x, m32: newZ.y, m33: newZ.z, m34: 0,
                                    m41: position.x, m42: position.y, m43: position.z, m44: 1.0)
    return transform
    
}

public extension SCNMatrix4 {
    
    // format matrix for numpy (printed in row-major form)
    var np: String {
        get {
            let f: (Float) -> String = { num in
                return String(format: "%.4f", num)
            }
            let row1 = "[\(f(m11)), \(f(m21)), \(f(m31)), \(f(m41))]"
            let row2 = "[\(f(m12)), \(f(m22)), \(f(m32)), \(f(m42))]"
            let row3 = "[\(f(m13)), \(f(m23)), \(f(m33)), \(f(m43))]"
            let row4 = "[\(f(m14)), \(f(m24)), \(f(m34)), \(f(m44))]"
            return "\narray([\n  \(row1),\n  \(row2),\n  \(row3),\n  \(row4)\n])"
        }
    }
    
    var rowMajorArray : [Float] {
        get {
            let mat : [Float] = [m11, m21, m31, m41,
                                 m12, m22, m32, m42,
                                 m13, m23, m33, m43,
                                 m14, m24, m34, m44]
            return mat
        }
    }
    
    var rowArrays : [[Float]] {
        get {
            return [[m11, m21, m31, m41],
                    [m12, m22, m32, m42],
                    [m13, m23, m33, m43],
                    [m14, m24, m34, m44]]
            
        }
    }
    
    var xAxis: SCNVector3 {
        get {
            return SCNVector3(self.m11, self.m12, self.m13)
        }
        set {
            self.m11 = newValue.x
            self.m12 = newValue.y
            self.m13 = newValue.z
        }
    }
    var yAxis: SCNVector3 {
        get {
            return SCNVector3(self.m21, self.m22, self.m23)
        }
        set {
            self.m21 = newValue.x
            self.m22 = newValue.y
            self.m23 = newValue.z
        }
    }
    var zAxis: SCNVector3 {
        get {
            return SCNVector3(self.m31, self.m32, self.m33)
        }
        set {
            self.m31 = newValue.x
            self.m32 = newValue.y
            self.m33 = newValue.z
        }
    }
    var translation: SCNVector3 {
        get {
            return SCNVector3(self.m41, self.m42, self.m43)
        }
        set {
            self.m41 = newValue.x
            self.m42 = newValue.y
            self.m43 = newValue.z
        }
    }
    var sceneKitCameraDirection : SCNVector3 {
        return self.zAxis * -1.0
    }
    
    init(rowMajor floats: [Float]) {
        var rows: [SIMD4<Float>] = []
        (0...3).forEach {
            let row = $0 * 4
            var values = SIMD4<Float>()
            (0...3).forEach { values[$0] = floats[row + $0] }
            rows.append(values)
        }
        
        let matrix = matrix_float4x4(rows: rows)
        self.init(matrix)
    }
    
}

public extension matrix_float4x4 {
    
    // format matrix for numpy
    var np: String {
        get {
            return SCNMatrix4.init(self).np
        }
    }
    
    var rowMajorArray : [Float] {
        get {
            return SCNMatrix4.init(self).rowMajorArray
        }
    }
    var rowArrays : [[Float]] {
        get {
            return SCNMatrix4.init(self).rowArrays
        }
    }
        
}
