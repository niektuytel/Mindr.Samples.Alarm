using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using AutoMapper;
using Alarm.Api.Models.Alarm;
using Grpc.Core;
using Alarm.Api.Profiles;
using Microsoft.Extensions.Configuration;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration(c =>
    {
        c.AddEnvironmentVariables();
        c.AddJsonFile("local.settings.json");
    })
    .ConfigureServices(services =>
    {
        services.AddAutoMapper(cfg => cfg.AddProfile<MappingProfile>(), typeof(Program));
        services.AddHttpClient();

        services.AddScoped<INotificationService, NotificationService>();
    })
    .Build();

host.Run();
