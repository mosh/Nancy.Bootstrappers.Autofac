namespace Nancy.Bootstrappers.Autofac;

uses
  Autofac,
  Autofac.Core.Lifetime,
  Nancy,
  Nancy.Bootstrapper,
  Nancy.Configuration,
  Nancy.Diagnostics, System.Collections.Generic;

type
  AutofacNancyBootstrapper = public abstract class(NancyBootstrapperWithRequestContainerBase<ILifetimeScope>)

  protected

    method GetDiagnostics:IDiagnostics;override;
    begin
      exit self.ApplicationContainer.Resolve<IDiagnostics>;
    end;

    /// <summary>
    /// Gets all registered application startup tasks
    /// </summary>
    /// <returns>An <see cref="System.Collections.Generic.IEnumerable{T}"/> instance containing <see cref="IApplicationStartup"/> instances. </returns>
    method GetApplicationStartupTasks:IEnumerable<IApplicationStartup>;override;
    begin
        exit self.ApplicationContainer.Resolve<IEnumerable<IApplicationStartup>>;
    end;

    /// <summary>
    /// Gets all registered request startup tasks
    /// </summary>
    /// <returns>An <see cref="IEnumerable{T}"/> instance containing <see cref="IRequestStartup"/> instances.</returns>
    method RegisterAndGetRequestStartupTasks(container:ILifetimeScope; requestStartupTypes: array of &Type):IEnumerable<IRequestStartup> ;override;
    begin
        container.Update(builder ->
          begin
            for each  requestStartupType in requestStartupTypes do
            begin
                builder.RegisterType(requestStartupType).As<IRequestStartup>().PreserveExistingDefaults().InstancePerDependency();
            end;
          end);

      exit container.Resolve<IEnumerable<IRequestStartup>>();
    end;

    /// <summary>
    /// Gets all registered application registration tasks
    /// </summary>
    /// <returns>An <see cref="System.Collections.Generic.IEnumerable{T}"/> instance containing <see cref="IRegistrations"/> instances.</returns>
    method GetRegistrationTasks:IEnumerable<IRegistrations> ;override;
    begin
      exit self.ApplicationContainer.Resolve<IEnumerable<IRegistrations>>();
    end;

    /// <summary>
    /// Get INancyEngine
    /// </summary>
    /// <returns>INancyEngine implementation</returns>
    method GetEngineInternal:INancyEngine;override;
    begin
      exit self.ApplicationContainer.Resolve<INancyEngine>();
    end;

    /// <summary>
    /// Gets the <see cref="INancyEnvironmentConfigurator"/> used by th.
    /// </summary>
    /// <returns>An <see cref="INancyEnvironmentConfigurator"/> instance.</returns>
    method GetEnvironmentConfigurator:INancyEnvironmentConfigurator;override;
    begin
        exit self.ApplicationContainer.Resolve<INancyEnvironmentConfigurator>();
    end;


    /// <summary>
    /// Registers an <see cref="INancyEnvironment"/> instance in the container.
    /// </summary>
    /// <param name="container">The container to register into.</param>
    /// <param name="environment">The <see cref="INancyEnvironment"/> instance to register.</param>
    method RegisterNancyEnvironment(container:ILifetimeScope; environment:INancyEnvironment);override;
    begin
      container.Update(builder -> builder.RegisterInstance(environment));
    end;

    /// <summary>
    /// Create a default, unconfigured, container
    /// </summary>
    /// <returns>Container instance</returns>
    method GetApplicationContainer():ILifetimeScope;override;
    begin
        exit new ContainerBuilder().Build();
    end;

    /// <summary>
    /// Bind the bootstrapper's implemented types into the container.
    /// This is necessary so a user can pass in a populated container but not have
    /// to take the responsibility of registering things like INancyModuleCatalog manually.
    /// </summary>
    /// <param name="applicationContainer">Application container to register into</param>
    method RegisterBootstrapperTypes(applicationContainer:ILifetimeScope);override;
    begin
      applicationContainer.Update(builder -> builder.RegisterInstance(self).As<INancyModuleCatalog>());
    end;

    /// <summary>
    /// Bind the default implementations of internally used types into the container as singletons
    /// </summary>
    /// <param name="container">Container to register into</param>
    /// <param name="typeRegistrations">Type registrations to register</param>
    method RegisterTypes(container:ILifetimeScope; typeRegistrations:IEnumerable<TypeRegistration>);override;
    begin
      container.Update(builder ->
      begin
          for each typeRegistration in typeRegistrations do
          begin
              case typeRegistration.Lifetime of

                  Lifetime.Transient: builder.RegisterType(typeRegistration.ImplementationType).As(typeRegistration.RegistrationType).InstancePerDependency();
                  Lifetime.Singleton: builder.RegisterType(typeRegistration.ImplementationType).As(typeRegistration.RegistrationType).SingleInstance();
                  Lifetime.PerRequest: raise new InvalidOperationException("Unable to directly register a per request lifetime.");
                  else
                      raise new ArgumentOutOfRangeException();
              end;
          end;
      end);
    end;

    /// <summary>
    /// Bind the various collections into the container as singletons to later be resolved
    /// by IEnumerable{Type} constructor dependencies.
    /// </summary>
    /// <param name="container">Container to register into</param>
    /// <param name="collectionTypeRegistrations">Collection type registrations to register</param>
    method RegisterCollectionTypes(container:ILifetimeScope; collectionTypeRegistrations:IEnumerable<CollectionTypeRegistration>);override;
    begin
      container.Update(builder ->
      begin
          for each collectionTypeRegistration in collectionTypeRegistrations do
          begin
              for each implementationType in collectionTypeRegistration.ImplementationTypes do
              begin
                  case collectionTypeRegistration.Lifetime of
                      Lifetime.Transient: builder.RegisterType(implementationType).As(collectionTypeRegistration.RegistrationType).PreserveExistingDefaults().InstancePerDependency();
                      Lifetime.Singleton: builder.RegisterType(implementationType).As(collectionTypeRegistration.RegistrationType).PreserveExistingDefaults().SingleInstance();
                      Lifetime.PerRequest: raise new InvalidOperationException("Unable to directly register a per request lifetime.");
                      else
                          raise new ArgumentOutOfRangeException();
                  end;
              end;
          end;
      end);
    end;

    /// <summary>
    /// Bind the given instances into the container
    /// </summary>
    /// <param name="container">Container to register into</param>
    /// <param name="instanceRegistrations">Instance registration types</param>
    method RegisterInstances(container:ILifetimeScope; instanceRegistrations:IEnumerable<InstanceRegistration>);override;
    begin
      container.Update(builder ->
      begin
          for each instanceRegistration in instanceRegistrations do
          begin
              builder.RegisterInstance(instanceRegistration.Implementation).As(instanceRegistration.RegistrationType);
          end;
      end);
    end;

    /// <summary>
    /// Creates a per request child/nested container
    /// </summary>
    /// <param name="context">Current context</param>
    /// <returns>Request container instance</returns>
    method  CreateRequestContainer(context:NancyContext):ILifetimeScope;override;
    begin
      exit ApplicationContainer.BeginLifetimeScope(MatchingScopeLifetimeTags.RequestLifetimeScopeTag);
    end;

    /// <summary>
    /// Bind the given module types into the container
    /// </summary>
    /// <param name="container">Container to register into</param>
    /// <param name="moduleRegistrationTypes"><see cref="INancyModule"/> types</param>
    method RegisterRequestContainerModules(container:ILifetimeScope; moduleRegistrationTypes:IEnumerable<ModuleRegistration>);override;
    begin
      container.Update(builder ->
      begin
          for each moduleRegistrationType in moduleRegistrationTypes do
          begin
              builder.RegisterType(moduleRegistrationType.ModuleType).As<INancyModule>();
          end;
      end);
    end;

    /// <summary>
    /// Retrieve all module instances from the container
    /// </summary>
    /// <param name="container">Container to use</param>
    /// <returns>Collection of <see cref="INancyModule"/> instances</returns>
    method GetAllModules(container:ILifetimeScope):IEnumerable<INancyModule> ;override;
    begin
      exit container.Resolve<IEnumerable<INancyModule>>();
    end;

    /// <summary>
    /// Retreive a specific module instance from the container
    /// </summary>
    /// <param name="container">Container to use</param>
    /// <param name="moduleType">Type of the module</param>
    /// <returns>An <see cref="INancyModule"/> instance</returns>
    method GetModule(container:ILifetimeScope; moduleType:&Type):INancyModule;override;
    begin
      exit container.Update(builder -> builder.RegisterType(moduleType).As<INancyModule>()).Resolve<INancyModule>();
    end;

  public
    /// <summary>
    /// Get the <see cref="INancyEnvironment" /> instance.
    /// </summary>
    /// <returns>An configured <see cref="INancyEnvironment" /> instance.</returns>
    /// <remarks>The boostrapper must be initialised (<see cref="INancyBootstrapper.Initialise" />) prior to calling this.</remarks>
    method GetEnvironment():INancyEnvironment; override;
    begin
        exit self.ApplicationContainer.Resolve<INancyEnvironment>();
    end;


  end;
end.