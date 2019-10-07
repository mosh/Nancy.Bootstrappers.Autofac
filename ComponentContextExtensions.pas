namespace Nancy.Bootstrappers.Autofac;

uses
  Autofac;


type
  ComponentContextExtensions = public extension class(IComponentContext)
  public
    method Update(builderAction: Action<ContainerBuilder>): IComponentContext;
    begin
      if not assigned(self) then
      begin
        raise new ArgumentNullException('context');
      end;
      if not assigned(builderAction) then
      begin
        raise new ArgumentNullException('builderAction');
      end;
      var builder := new ContainerBuilder();
      builderAction.Invoke(builder);
      builder.Update(self.ComponentRegistry);
      exit self;
    end;
  end;

end.