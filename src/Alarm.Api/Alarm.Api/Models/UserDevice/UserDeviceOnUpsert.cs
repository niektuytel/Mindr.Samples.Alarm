using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Alarm.Api.Models.Alarm;

internal class UserDeviceOnUpsert
{
    [JsonRequired]
    [JsonPropertyName("user_id")]
    public Guid UserId { get; set; }

    [JsonRequired]
    [JsonPropertyName("device_token")]
    public string? DeviceToken { get; set; }
}
