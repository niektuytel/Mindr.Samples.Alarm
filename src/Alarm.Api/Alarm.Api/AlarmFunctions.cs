using System.Net;
using System.Text.Json;
using Alarm.Api.Models.Alarm;
using AutoMapper;
using Azure;
using Azure.Data.Tables;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace Alarm.Api;

public class AlarmFunctions
{
    private readonly ILogger _logger;
    private readonly IMapper _mapper;
    private readonly TableClient _tableClient;

    public AlarmFunctions(ILoggerFactory loggerFactory, IMapper mapper)
    {
        _logger = loggerFactory.CreateLogger<AlarmFunctions>();
        _mapper = mapper;
        _tableClient = new TableClient("DefaultEndpointsProtocol=https;AccountName=alarmteststorage;AccountKey=bwiLZlWZFsEaILVJeEisdySL4mHmN7XQ6SpIE0+AWDa+go5O0nIy/ndbNKld1I6pszKHmkWTa6Yi+AStGjp1PA==;EndpointSuffix=core.windows.net", "Alarms");
    }
    
    [Function(nameof(GetAlarm))]
    public async Task<HttpResponseData> GetAlarm([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "alarms/{id}")] HttpRequestData req, Guid id)
    {
        var entity = await _tableClient.GetEntityAsync<AlarmEntity>(id.ToString(), id.ToString());

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");

        await response.WriteStringAsync(JsonSerializer.Serialize(entity));

        return response;
    }

    [Function(nameof(CreateAlarm))]
    public async Task<HttpResponseData> CreateAlarm([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "alarms")] HttpRequestData req)
    {
        string requestBody = await req.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<AlarmOnCreate>(requestBody);

        var entity = _mapper.Map<AlarmOnCreate, AlarmEntity>(data);
        await _tableClient.AddEntityAsync(entity);

        var response = req.CreateResponse(HttpStatusCode.Created);
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");

        await response.WriteStringAsync(JsonSerializer.Serialize(data));

        return response;
    }

    [Function(nameof(UpdateAlarm))]
    public async Task<HttpResponseData> UpdateAlarm([HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "alarms/{id}")] HttpRequestData req, Guid id)
    {
        string requestBody = await req.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<AlarmOnUpdate>(requestBody);

        data.Id = id;
        var entity = _mapper.Map<AlarmOnUpdate, AlarmEntity>(data);
        await _tableClient.UpdateEntityAsync(entity, ETag.All);

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");

        await response.WriteStringAsync(JsonSerializer.Serialize(data));

        return response;
    }

    [Function(nameof(DeleteAlarm))]
    public async Task<HttpResponseData> DeleteAlarm([HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "alarms/{id}")] HttpRequestData req, Guid id)
    {
        await _tableClient.DeleteEntityAsync(id.ToString(), id.ToString());

        var response = req.CreateResponse(HttpStatusCode.NoContent);
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");

        return response;
    }
}
