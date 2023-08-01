using System.Net;
using System.Text.Json;
using Alarm.Api.Extentions;
using Alarm.Api.Models.Alarm;
using Alarm.Api.Models.AlarmAction;
using Alarm.Api.Models.AlarmConnection;
using AutoMapper;
using Azure;
using Azure.Core;
using Azure.Data.Tables;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Alarm.Api.Functions;

public class AlarmActionFunctions
{
    const string _tableName = "AlarmActions";

    private readonly ILogger _logger;
    private readonly IMapper _mapper;
    private readonly TableClient _tableClient;
    private readonly TableClient _userDevicesTableClient;
    private readonly INotificationService _notificationService;
    

    public AlarmActionFunctions(ILoggerFactory loggerFactory, IMapper mapper, IConfiguration configuration, INotificationService notificationService)
    {
        _logger = loggerFactory.CreateLogger<AlarmActionFunctions>();
        _mapper = mapper;

        var connectionString = configuration["ConnectionStrings:AlarmStorageTables"];
        _tableClient = new TableClient(connectionString, _tableName);
        _tableClient.CreateIfNotExists();

        _userDevicesTableClient = new TableClient(connectionString, UserDeviceFunctions.TableName);
        _userDevicesTableClient.CreateIfNotExists();

        _notificationService = notificationService;
    }

    [Function(nameof(Push))]
    public async Task<HttpResponseData> Push([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = $"{_tableName}/{nameof(Push)}")] HttpRequestData req)
    {
        var response = req.CreateResponse();

        try
        {
            var data = await req.GetAlarmActionOnPush();
            var entity = _mapper.Map<AlarmActionOnPush, AlarmActionEntity>(data);
            if (entity == null)
            {
                throw new Exception($"Argument null exception: {{{nameof(entity)}:'Invalid data input.'}}");
            }

            // Fetch the user device data.
            string userDeviceFilter = $"(PartitionKey eq '{entity.UserId}' and RowKey eq '{entity.UserId}')";
            var userDevice = _userDevicesTableClient
                .Query<UserDeviceEntity>(userDeviceFilter, maxPerPage: 1)
                .FirstOrDefault();

            if (userDevice == null)
            {
                response.StatusCode = HttpStatusCode.NotFound;
                response.Headers.Add("Content-Type", "application/json; charset=utf-8");
                await response.WriteStringAsync(JsonSerializer.Serialize(new { Error = $"No matching user device entity found on user {entity.UserId}." }));
                return response;
            }

            // call fcm request to trigger user device
            var title = "New alarm";
            var body = string.IsNullOrEmpty(data.Alarm.Label) ? $"trigger at {data.Alarm.Time}" : $"'{data.Alarm.Label}' at {data.Alarm.Time}";
            entity.LatestCloudMessage = await _notificationService.SendNotificationAsync(userDevice.DeviceToken, title, body, data);

            _ = await _tableClient.UpsertEntityAsync(entity);

            response.StatusCode = HttpStatusCode.OK;
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(entity.LatestCloudMessage));
        }
        catch (Exception ex)
        {
            _logger.LogError($"An error occurred during push operation: {ex.Message}");

            response.StatusCode = HttpStatusCode.BadRequest;
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(new { Error = ex.Message }));
        }

        return response;
    }
}
