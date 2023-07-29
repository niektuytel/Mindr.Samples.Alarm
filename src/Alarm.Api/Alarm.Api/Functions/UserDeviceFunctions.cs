using System.Net;
using System.Text.Json;
using Alarm.Api.Models.Alarm;
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

public class UserDeviceFunctions
{
    public const string TableName = "UserDevices";

    private readonly ILogger _logger;
    private readonly IMapper _mapper;
    private readonly TableClient _tableClient;

    public UserDeviceFunctions(ILoggerFactory loggerFactory, IMapper mapper, IConfiguration configuration)
    {
        _logger = loggerFactory.CreateLogger<AlarmActionFunctions>();
        _mapper = mapper;

        var connectionString = configuration.GetConnectionString("AlarmStorageTables");
        _tableClient = new TableClient(connectionString, TableName);
        _tableClient.CreateIfNotExists();
    }

    [Function(nameof(GetUserDevice))]
    public async Task<HttpResponseData> GetUserDevice([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = $"{TableName}/{{userId}}")] HttpRequestData req, Guid userId)
    {
        if (userId == Guid.Empty)
        {
            var errorResponse = req.CreateResponse(HttpStatusCode.BadRequest);
            await errorResponse.WriteStringAsync("Invalid userId.");
            return errorResponse;
        }

        //string filter = $"(UserId eq '{userId}')";
        string filter = $"(PartitionKey eq '{userId}' and RowKey eq '{userId}')";
        var userDevice = _tableClient
            .Query<UserDeviceEntity>(filter, maxPerPage: 1)
            .FirstOrDefault();

        var response = req.CreateResponse();
        if (userDevice != null)
        {
            response.StatusCode = HttpStatusCode.OK;
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(userDevice));
        }
        else
        {
            response.StatusCode = HttpStatusCode.NotFound;
            await response.WriteStringAsync("No matching entity found.");
        }

        return response;
    }

    [Function(nameof(UpsertUserDevice))]
    public async Task<HttpResponseData> UpsertUserDevice([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = $"{TableName}")] HttpRequestData req)
    {
        string requestBody = await req.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<UserDeviceOnUpsert>(requestBody);
        var entity = _mapper.Map<UserDeviceOnUpsert, UserDeviceEntity>(data);

        if (entity == null)
        {
            var errorResponse = req.CreateResponse(HttpStatusCode.BadRequest);
            await errorResponse.WriteStringAsync("Invalid data.");
            return errorResponse;
        }

        var response = req.CreateResponse();
        try
        {
            var result = await _tableClient.UpsertEntityAsync(entity);

            response.StatusCode = (HttpStatusCode)result.Status;
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(data));
        }
        catch (Exception ex)
        {
            _logger.LogError($"An error occurred during upsert operation: {ex.Message}");

            response.StatusCode = HttpStatusCode.InternalServerError;
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(new { Error = ex.Message }));
        }

        return response;
    }
    
    [Function(nameof(DeleteUserDevice))]
    public async Task<HttpResponseData> DeleteUserDevice([HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = $"{TableName}/{{userId}}")] HttpRequestData req, Guid userId)
    {
        if (userId == Guid.Empty)
        {
            var errorResponse = req.CreateResponse(HttpStatusCode.BadRequest);
            await errorResponse.WriteStringAsync("Invalid userId.");
            return errorResponse;
        }

        await _tableClient.DeleteEntityAsync(userId.ToString(), userId.ToString());

        var response = req.CreateResponse(HttpStatusCode.NoContent);
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");
        return response;
    }
}
