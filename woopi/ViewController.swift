//
//  ViewController.swift
//  woopi
//
//  Created by Candy on 11/04/2019.
//  Copyright © 2019 Torres. All rights reserved.
//

import UIKit

struct Mapa{
    let direccTemp: Int //??
    let const : [String : Any]
    let direccVar: Int
    let direccConst: Int //???
    let cuadruplos: [[String]]
    let funcs : [[String:Any]]
}

struct Funcion{ //funcs
    let `Type` : String
    let Func : String
    let pointer: Int?
    let vars: [String:Variable]
}

struct Variable{ //vars
    let Var : String
    let dir: Int
    let `Type`: String
    let is_param : Bool
    let context : Int
    let order:Int? //?
    var value:Any? //?
}

//* stack- LIFO
class Stack<Element> {
    public var stackArray = [Element]()
    
    //push function
    func push(stringToPush: Element){
        self.stackArray.append(stringToPush)
    }
    // pop function
    func pop() -> Element? {
        if self.stackArray.last != nil { //if there are elements in the stack
            let stringToReturn = self.stackArray.last
            self.stackArray.removeLast() //removig from the stack the top element in it
            return stringToReturn!
        } else {
            return nil
        }
    }
    // bottom function- to access the first element added- the element at the bottom of the stack
    func bottom() -> Element? {
        if self.stackArray.last != nil {
            let stringToReturn = self.stackArray.first
            return stringToReturn!
        } else {
            return nil
        }
    }
    //create top function-> access the top element without removing it
    func top() -> Element? {
        if self.stackArray.last != nil {
            let stringToReturn = self.stackArray.last
            return stringToReturn!
        } else {
            return nil
        }
    }
    //size of the stack
    func size(){
        self.stackArray.count
    }
}

class ViewController: UIViewController{
    
    var mapa : Mapa?
    var pointer = 0
    
    //**
    var currentContext = 0 //global
    //**
    var virtualMem = Stack<Funcion>()
    //**
    var returnStack = Stack<Funcion>()
    
    override func viewDidLoad() { //read all the data sent by the compiler - dictionary
        super.viewDidLoad()
        
        if let filepath = Bundle.main.path(forResource: "code", ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                print(contents) //print the content of the .txt
                
                do{
                    //here dataResponse received from a network request
                    let jsonResponsex = try JSONSerialization.jsonObject(with: Data(contents.utf8), options: [])
                    print(jsonResponsex) //Response result
                    let jsonResponse = jsonResponsex as! [String: Any]
                    mapa = Mapa(
                        direccTemp: jsonResponse["direccTemp"] as? Int ?? -1, //?
                        const: jsonResponse["const"] as? [String:Any] ?? [:],
                        direccVar: jsonResponse["direccVar"] as? Int ?? -1,
                        direccConst: jsonResponse["direccConst"] as? Int ?? -1, //?
                        cuadruplos: jsonResponse["cuadruplos"] as! [[String]],
                        funcs: jsonResponse["funcs"] as! [[String : Any]])
                    
                    execute();
                    
                } catch let parsingError {
                    print("JasonError", parsingError)
                }
            } catch {
                print("Contents could not be loaded")
            }
        } else {
    
            print("Example.txt not found!")
        }
    }
    
    func getValue(dir: String) -> Any?{
        var x = dir;
        var isPointer = false;
        if (dir.prefix(1) == "*"){
            x.remove(at: x.startIndex)
            return Int(x);
        }else if (dir.prefix(1) == "&"){
            x.remove(at: x.startIndex);
            isPointer = true;
        }
        
        var localFunc = virtualMem.top()! //localFunc : type, vars, func
     
        for (key, value) in localFunc.vars{ // vars: key : var, dir, type, is_param, context
            if (key == x){
                if (isPointer){
                    return getValue(dir: value.value as! String);
                }
                return value.value //return: var, dir, type, is_param, context
            }
        }
        
        localFunc = virtualMem.bottom()!
        for (key, value) in localFunc.vars{
            if (key == String(dir)){
                if (isPointer){
                    return getValue(dir: value.value as! String);
                }
                return value.value
            }
        }
        return nil
    }
    
    func setValue(dir: String, valueX: Any?){ //value is the dictionary of var, dir, type, is_param, context
        
        var x = dir;
        var isPointer = false;
       if (dir.prefix(1) == "&"){
            x.remove(at: x.startIndex);
            isPointer = true;
        }
        
        var localFunc = virtualMem.top()! //localFunc : type, vars, func
        var keys = Array(localFunc.vars.keys)
        for n in 1...keys.count { // vars: key : var, dir, type, is_param, context
            if (keys[n - 1] == x){
                if (isPointer){
                    setValue(dir: localFunc.vars[keys[n - 1]]?.value as! String, valueX: valueX);
                    return;
                }
            }
        }
        
        localFunc = virtualMem.bottom()!
        keys = Array(localFunc.vars.keys)
        for n in 1...keys.count { // vars: key : var, dir, type, is_param, context
            if (keys[n - 1] == x){
                if (isPointer){
                    setValue(dir: localFunc.vars[keys[n - 1]]?.value as! String, valueX: valueX);
                    return;
                }
            }
        }
    }
 
    
    //**
    func getFuncion(funcName: String) -> Funcion{
        
        var fun : [String : Any]? = nil
        for f in mapa!.funcs{
            if (funcName == f["Func"] as! String){
                fun = f;
            }
        }
        
        var fu = fun!
        var vardict = [String:Variable]()
        for (key, value) in (fu["vars"] as! [String:[String: Any]]){ //???
            vardict[key] = Variable(
            Var : value["Var"] as! String,
            dir: value["dir"] as! Int,
            Type: value["Type"] as! String,
            is_param : value["is_param"] as! Bool,
            context : value["context"] as! Int,
            order: value["order"] as? Int,
            value: nil
            )
        }
        let funcion = Funcion(Type:fu["Type"] as! String,Func:fu["Func"] as! String,pointer:fu["pointer"] as? Int,vars:vardict)
        
        return funcion
    }
    
    func execute(){
        if (pointer == 0){
            virtualMem.push(stringToPush: getFuncion(funcName: "global"))
        }
        
        while (pointer < mapa!.cuadruplos.count){
            let cuadruplo = mapa!.cuadruplos[pointer]
            print(cuadruplo)
            let command = cuadruplo[0]
            
            if (command == "goto"){
                pointer = Int(cuadruplo[3]) ?? 1000000;
            }else if (command == "gotoF"){
                if (getValue(dir: cuadruplo[1]) as! Bool ){
                    pointer = Int(cuadruplo[3]) ?? 1000000;
                }
            }else if (command == "+"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]
                
                setValue(dir: dir_v3, valueX: (Float(dir_v1) ?? 0.0) + (Float(dir_v2) ?? 0.0))
                
                
                //setValue(dir: dir_v3, value: ((getValue(dir:dir_v1) as! Double) + (getValue(dir:dir_v2) as! Double)))
            }else if(command == "-"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]

                
            }else if(command == "*"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]

                
            }else if(command == "/"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]

            }else if(command == "="){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[3]
                
                
            }else if(command == "<"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]
                
            }else if(command == ">"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]
                
            }else if(command == "<="){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]
                
            }else if(command == ">="){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]
                
            }else if(command == "=="){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]
                
            }else if(command == "returnoo"){
                let dir_v1 = cuadruplo[3]
                
            }else if(command == "endFunc"){
                
                
            }else if(command == "era"){
                let dir_v1 = cuadruplo[1]
                
            }else if(command == "param"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[3]
                
            }else if(command == "gosub"){
                let dir_v1 = cuadruplo[3]
                
            }else if(command == "writeoo"){
                let dir_v1 = cuadruplo[3]
                
            }else if(command == "|"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]
                
            }else if(command == "ver"){
                let dir_v1 = cuadruplo[1]
                let dir_v2 = cuadruplo[2]
                let dir_v3 = cuadruplo[3]
                
            }else if(command == "readoo"){
                let dir_v1 = cuadruplo[3]
                
            }else if(command == "getoo"){
                let dir_v1 = cuadruplo[2]
                let dir_v2 = cuadruplo[3]
                
            }else if(command == "savoo"){
                let dir_v1 = cuadruplo[2]
                let dir_v2 = cuadruplo[3]
            }
            
            pointer = pointer + 1;
        }
    }

 
}


