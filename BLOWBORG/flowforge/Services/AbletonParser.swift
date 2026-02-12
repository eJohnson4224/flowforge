//
//  AbletonParser.swift
//  flowforge
//
//  Parses Ableton Live .als project files to extract sample references
//

import Foundation
import Compression

/// Parser for Ableton Live .als project files
class AbletonParser {
    
    // MARK: - Public Methods
    
    /// Parse an .als file and extract all sample references
    static func parseSampleReferences(from alsURL: URL) -> [SampleReference] {
        guard alsURL.pathExtension.lowercased() == "als" else {
            print("⚠️ Not an .als file: \(alsURL.lastPathComponent)")
            return []
        }
        
        // Step 1: Read and decompress the .als file
        guard let xmlString = decompressALSFile(at: alsURL) else {
            print("❌ Failed to decompress .als file: \(alsURL.lastPathComponent)")
            return []
        }
        
        // Step 2: Parse XML to extract sample paths
        let samplePaths = extractSamplePaths(from: xmlString)
        
        // Step 3: Convert to SampleReference objects
        let projectName = alsURL.deletingPathExtension().lastPathComponent
        return samplePaths.map { path in
            let isRelative = !path.hasPrefix("/")
            return SampleReference(
                projectName: projectName,
                samplePath: path,
                isRelative: isRelative
            )
        }
    }
    
    // MARK: - Decompression
    
    /// Decompress .als file (gzipped XML) and return XML string
    private static func decompressALSFile(at url: URL) -> String? {
        guard let compressedData = try? Data(contentsOf: url) else {
            return nil
        }
        
        // .als files are gzipped XML
        guard let decompressedData = decompressGzip(data: compressedData) else {
            return nil
        }
        
        return String(data: decompressedData, encoding: .utf8)
    }
    
    /// Decompress gzipped data using Compression framework
    private static func decompressGzip(data: Data) -> Data? {
        // .als files use gzip compression - use NSData decompression
        guard let decompressedData = try? (data as NSData).decompressed(using: .zlib) as Data else {
            print("❌ Decompression failed")
            return nil
        }

        print("✅ Decompressed \(data.count) bytes → \(decompressedData.count) bytes")
        return decompressedData
    }
    
    // MARK: - XML Parsing
    
    /// Extract sample paths from Ableton XML
    private static func extractSamplePaths(from xmlString: String) -> [String] {
        var samplePaths: [String] = []
        
        // Parse XML using XMLParser
        let parser = AbletonXMLParser()
        if let data = xmlString.data(using: .utf8) {
            let xmlParser = XMLParser(data: data)
            xmlParser.delegate = parser
            xmlParser.parse()
            samplePaths = parser.samplePaths
        }
        
        return samplePaths
    }
}

// MARK: - XML Parser Delegate

/// Custom XML parser delegate to extract sample paths from Ableton XML
private class AbletonXMLParser: NSObject, XMLParserDelegate {
    var samplePaths: [String] = []
    private var currentElement: String = ""
    private var currentPath: String = ""
    private var isInFileRef: Bool = false
    private var isInRelativePath: Bool = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        // Look for FileRef elements (contain sample paths)
        if elementName == "FileRef" {
            isInFileRef = true
        }
        
        // Look for RelativePathElement or Path elements
        if isInFileRef && (elementName == "RelativePathElement" || elementName == "Path") {
            isInRelativePath = true
        }
        
        // Check for Value attribute (Ableton stores paths here)
        if isInRelativePath, let value = attributeDict["Value"] {
            if !currentPath.isEmpty {
                currentPath += "/"
            }
            currentPath += value
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // When FileRef ends, save the path
        if elementName == "FileRef" {
            if !currentPath.isEmpty {
                samplePaths.append(currentPath)
                currentPath = ""
            }
            isInFileRef = false
        }
        
        if elementName == "RelativePathElement" || elementName == "Path" {
            isInRelativePath = false
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Some paths might be in character data
        if isInRelativePath {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                if !currentPath.isEmpty {
                    currentPath += "/"
                }
                currentPath += trimmed
            }
        }
    }
}

