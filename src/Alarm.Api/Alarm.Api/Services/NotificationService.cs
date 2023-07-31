using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Xml.Linq;
using Alarm.Api.Models;
using Alarm.Api.Models.Alarm;
using Alarm.Api.Models.AlarmAction;
using Microsoft.Extensions.Configuration;
using static Grpc.Core.Metadata;

public class NotificationService : INotificationService
{
    private readonly HttpClient _client;
    private readonly string _serverKey;
    private readonly string _senderId;

    public NotificationService(IHttpClientFactory httpFactory, IConfiguration configuration)
    {
        _client = httpFactory.CreateClient();
        _serverKey = configuration["NotificationServer:ServerKey"];
        _senderId = configuration["NotificationServer:SenderId"]; ;
    }

    public async Task<CloudMessageResponse> SendNotificationAsync(string fcmToken, string title, string body, AlarmActionOnPush alarmAction)
    {
        _client.DefaultRequestHeaders.TryAddWithoutValidation("Authorization", $"key={_serverKey}");
        _client.DefaultRequestHeaders.TryAddWithoutValidation("Sender", $"id={_senderId}");

        var data = new
        {
            to = fcmToken,
            notification = new
            {
                title = title,
                body = body
            },
            data = alarmAction
        };

        var json = JsonSerializer.Serialize(data);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _client.PostAsync("https://fcm.googleapis.com/fcm/send", content);
        var result = await response.Content.ReadAsStringAsync();

        var fcmResponse = JsonSerializer.Deserialize<CloudMessageResponse>(result);
        return fcmResponse;
    }
}
