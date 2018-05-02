//
//  CodeBuilder.swift
//  EXZLER
//
//  Created by EXZACKLY on 4/21/18.
//

import Foundation

class CodeBuilder {
    
    struct Code {
        var main = [String]()
        var `static` = [String]()
    }
    
    struct Locations {
        var idIndexMap = [Int: (location: String, type: VarType)]()
        var stringMap = [String: String]()
        var recycled = [String]()
        var backpatch = (static: [(name: String, offset: Int)](), jumps: [String:String]())
    }
    
    private let messenger: Messenger
    
    private var code = Code()
    private var locations = Locations()
    
    init(messenger: Messenger) {
        self.messenger = messenger
    }
    
    private func push(code: [String], reason: String) {
        messenger.message(type: .success, message: "Pushing \(code) to \(reason)")
        self.code.main += code
    }
    
    // MARK: - Op codes
    
    func loadAccumulator(with constant: Int) {
        push(code: ["A9", hex(for: constant)], reason: "load accumulator with constant")
    }
    
    func loadAccumulator(with constant: String) {
        push(code: ["A9", constant], reason: "load accumulator with constant")
    }
    
    func loadAccumulator(from location: String) {
        push(code: ["AD", location, "00"], reason: "load accumulator from location")
    }
    
    func storeAccumulator(at location: String) {
        push(code: ["8D", location, "00"], reason: "store accumulator at location")
    }
    
    func addWithCarry(from location: String) {
        push(code: ["6D", location, "00"], reason: "add from location with carry")
    }
    
    func loadXRegister(with constant: Int) {
        push(code: ["A2", hex(for: constant)], reason: "load x register with constant")
    }
    
    func loadXRegister(from location: String) {
        push(code: ["AE", location, "00"], reason: "load x register from memory")
    }
    
    func loadYRegister(with constant: Int) {
        push(code: ["A0", hex(for: constant)], reason: "load y register with constant")
    }
    
    func loadYRegister(from location: String) {
        push(code: ["AC", location, "00"], reason: "load y register from memory")
    }
    
    func noOperation() {
        push(code: ["EA"], reason: "no operation")
    }
    
    func `break`() {
        push(code: ["00"], reason: "break")
    }
    
    func compareXRegister(to location: String) {
        push(code: ["EC", location, "00"], reason: "compare x register to memory")
    }
    
    func branchIfNotEqual(bytes: Int) {
        push(code: ["D0", hex(for: bytes)], reason: "branch if not equal")
    }
    
    func branchIfNotEqualTemporary() -> String {
        let jumpSize = "R" + hex(for: locations.backpatch.jumps.count)
        locations.backpatch.jumps[jumpSize] = "00"
        push(code: ["D0", jumpSize], reason: "branch if not equal")
        return jumpSize
    }
    
    func increment(at location: String) {
        push(code: ["EE", location, "00"], reason: "increment byte at memory")
    }
    
    func systemCall() {
        push(code: ["FF"], reason: "system call")
    }
    
    // MARK: - Backpatching methods
    
    func generateTemporaryLocation(with staticHex: [String] = ["00"]) -> (location: String, isRecycled: Bool) {
        if staticHex == ["00"], let location = locations.recycled.popLast() { // Check if we have any used locations to recycle
            return (location: location, isRecycled: true)
        }
        let location = "Z" + hex(for: locations.backpatch.static.count) // We do not; make a new one
        locations.backpatch.static.append((name: location, offset: code.static.count))
        code.static += staticHex
        return (location: location, isRecycled: false)
    }
    
    func temporaryLocation(for node: ASTNode) -> (location: String, isRecycled: Bool) {
        guard let idData = locations.idIndexMap[node.idIndex!] else { // Lookup idIndex
            let temporaryLocation = generateTemporaryLocation() // idIndex not found; make a new one
            locations.idIndexMap[node.idIndex!] = (location: temporaryLocation.location, type: node.type!)
            return temporaryLocation
        }
        return (location: idData.location, isRecycled: false) // idIndex found; return corresponding location
    }
    
    func stringLocation(for string: String) -> String {
        let data = string.data(using: .utf8)!
        let hexString = data.map{ hex(for: $0) } + ["00"] // Turn string data into "00" terminated hex string
        locations.stringMap[string] = locations.stringMap[string] ?? generateTemporaryLocation(with: hexString).location // Lookup string; return or generate new one
        return locations.stringMap[string]!
    }
    
    func recycle(location: String) {
        locations.recycled.append(location)
    }
    
    func temporaryJump(named name: String, length: Int) {
        locations.backpatch.jumps[name] = hex(for: length)
    }
    
    func exportCode() -> String? {
        let size = code.main.count + code.static.count
        guard size > 1 else {
            messenger.message(type: .error, message: "No code generated")
            return nil
        }
        guard size <= 256 else {
            messenger.message(type: .error, message: "Code generated is greater than 256 bytes (\(size) bytes)")
            return nil
        }
        var backpatchedCode = code.main.joined(separator: " ") + " " + code.static.joined(separator: " ") // Join main and static code arrays into formatted string
        for item in locations.backpatch.static { // Backpatch static locations
            let location = hex(for: code.main.count + item.offset)
            messenger.message(type: .success, message: "Backpatching temporary location [ \(item.name) ] with [ \(location) ]")
            backpatchedCode = backpatchedCode.replacingOccurrences(of: item.name, with: location)
        }
        for jump in locations.backpatch.jumps.sorted(by: { $0.key < $1.key }) { // Backpatch jumps
            messenger.message(type: .success, message: "Backpatching jump [ \(jump.key) ] with [ \(jump.value) ]")
            backpatchedCode = backpatchedCode.replacingOccurrences(of: jump.key, with: jump.value)
        }
        messenger.message(type: .success, message: "Output size: \(size) bytes\n")
        return backpatchedCode
    }
    
    // MARK: - Helper methods
    
    private func hex(for item: CVarArg) -> String {
        return String(format: "%02X", item)
    }
    
    func codeSize() -> Int {
        return code.main.count
    }
    
}
