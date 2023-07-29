using Alarm.Api.Models.Alarm;
using Microsoft.Azure.Functions.Worker.Http;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Alarm.Api.Models.AlarmAction;

public class AlarmActionOnPush
{

    [JsonRequired]
    [JsonPropertyName("user_id")]
    public string? UserId { get; set; }

    [JsonRequired]
    [JsonPropertyName("action_type")]
    public string? ActionType { get; set; }

    [JsonRequired]
    [JsonPropertyName("alarm")]
    public AlarmOnPush Alarm { get; set; } = new AlarmOnPush();
}
