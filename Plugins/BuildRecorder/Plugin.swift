//
//  Plugin.swift
//  
//
//  Created by MainasuK on 2023-07-12.
//

import Foundation
import PackagePlugin

@main
struct BuildRecorder: BuildToolPlugin {
    
    func createBuildCommands(
        context: PackagePlugin.PluginContext,
        target: PackagePlugin.Target
    ) async throws -> [PackagePlugin.Command] {
        guard let target = target as? SourceModuleTarget else {
            return []
        }
        
        return try target.sourceFiles(withSuffix: "stub").compactMap { file in
            guard file.path.stem == "__GeneratedBuildRecord" else {
                return nil
            }
            let output = context.pluginWorkDirectory.appending(["__GeneratedBuildRecord.swift"])
            
            return .buildCommand(
                displayName: "Record build timestamp and save it",
                executable: try context.tool(named: "BuildRecorderExec").path,
                arguments: [output.string],
                outputFiles: [output]
            )
//            return .prebuildCommand(
//                displayName: "Record build timestamp and save it",
//                executable: try context.tool(named: "BuildRecorderExec").path,
//                arguments: [input],
//                outputFilesDirectory: <#T##Path#>
//            )
        }
    }
    
    
}
