using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using AutoMapper;
using Alarm.Api.Models.Alarm;
using Grpc.Core;
using Alarm.Api.Profiles;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        // Add AutoMapper
        services.AddAutoMapper(cfg => cfg.AddProfile<MappingProfile>(), typeof(Program));
    })
    .Build();

host.Run();
