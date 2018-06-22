//
//  ConfigurationController.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 11/04/2018.
//

import Foundation
import Vapor
import ApiCore
import DbCore
import Fluent
import FluentPostgreSQL


class ConfigurationController: Controller {
    
    static func boot(router: Router) throws {
        router.get("teams", DbCoreIdentifier.parameter, "config") { (req) -> Future<Config> in
            let teamId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: Config.self) { team in
                return try guaranteedConfig(for: teamId, on: req)
            }
        }
        
        router.post("teams", DbCoreIdentifier.parameter, "config") { (req) -> Future<Config> in
            let teamId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.content.decode(Config.self).flatMap(to: Config.self) { data in
                return try req.me.verifiedTeam(id: teamId).flatMap(to: Config.self) { team in
                    return try guaranteedConfig(for: teamId, on: req).flatMap(to: Config.self) { configuration in
                        configuration.teamId = teamId
                        configuration.theme = data.theme
                        configuration.apps = data.apps
                        return configuration.save(on: req)
                    }
                }
            }
        }
    }
    
}


extension ConfigurationController {
    
    private static func guaranteedConfig(for teamId: DbCoreIdentifier, on req: Request) throws -> Future<Config> {
        return try Config.query(on: req).filter(\Config.teamId == teamId).first().map(to: Config.self) { configuration in
            guard let configuration = configuration else {
                let theme = Config.Theme(
                    primaryColor: "000000",
                    primaryBackgroundColor: "FFFFFF",
                    primaryButtonColor: "FFFFFF",
                    primaryButtonBackgroundColor: "E94F91"
                )
                return Config(teamId: teamId, theme: theme)
            }
            return configuration
        }
    }
    
}
