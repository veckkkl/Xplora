//
//  ServiceLocator.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

final class ServiceLocator {
    static let shared = ServiceLocator()
    init() {}
    private var services: [ObjectIdentifier: Any] = [:]
    
    func register<Service>(_ type: Service.Type, instance: Service) {
        let key = ObjectIdentifier(type)
        services[key] = instance
    }
    
    func register<Service>(_ type: Service.Type, factory: @escaping () -> Service) {
        let key = ObjectIdentifier(type)
        services[key] = factory
    }
    
    func resolve<Service>(_ type: Service.Type) -> Service {
        let key = ObjectIdentifier(type)
        
        if let instance = services[key] as? Service {
            return instance
        }
        if let factory = services[key] as? () -> Service {
            let service = factory()
            services[key] = service
            return service
        }
        fatalError("No registered service for type")
    }
}
