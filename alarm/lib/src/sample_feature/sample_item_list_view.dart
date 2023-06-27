import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../feedback/feedback_view.dart';
import '../mindr/mindr_view.dart';
import '../settings/settings_view.dart';
import 'sample_item.dart';
import 'sample_item_details_view.dart';

class SampleItemListView extends StatefulWidget {
  static const routeName = '/';

  const SampleItemListView({
    Key? key,
    List<AlarmItem>? items,
  })  : _items = items,
        super(key: key);

  final List<AlarmItem>? _items;
  List<AlarmItem> get items => _items ?? sampleData;

  @override
  _SampleItemListViewState createState() => _SampleItemListViewState();
}

class _SampleItemListViewState extends State<SampleItemListView> {
  late final ScrollController _scrollController;
  Color _appBarColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  void _scrollListener() {
    final color = _scrollController.position.pixels > 10
        ? const Color.fromARGB(255, 119, 119, 119)
        : Colors.transparent;
    setState(() => _appBarColor = color);
  }

  @override
  Widget build(BuildContext context) {
    const dayNames = ["S", "M", "T", "W", "T", "F", "S"];

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              _buildListItem,
              childCount: widget.items.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Add your action here
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _appBarColor,
      title: const Text('Alarm'),
      actions: [_buildPopupMenu()],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<int>(
      color: const Color.fromARGB(255, 90, 90, 90),
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        if (value == 0) {
          Navigator.restorablePushNamed(context, MindrView.routeName);
        } else if (value == 1) {
          Navigator.restorablePushNamed(context, FeedbackView.routeName);
        } else if (value == 2) {
          Navigator.restorablePushNamed(context, SettingsView.routeName);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
            value: 0,
            child: Text('Mindr', style: TextStyle(color: Colors.white))),
        PopupMenuItem(
            value: 1,
            child:
                Text('Send feedback', style: TextStyle(color: Colors.white))),
        PopupMenuItem(
            value: 2,
            child: Text('Settings', style: TextStyle(color: Colors.white))),
      ],
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    final item = widget.items[index];
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: const Color.fromARGB(255, 53, 53, 53),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ExpansionTile(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        title: Text(
          DateFormat('h:mm a').format(item.time),
          style: TextStyle(
            fontWeight: item.isEnabled ? FontWeight.bold : FontWeight.normal,
            fontSize: 50,
            color: item.isEnabled
                ? Colors.white
                : const Color.fromARGB(255, 155, 155, 155),
          ),
        ),
        subtitle: _buildSubtitle(item),
        trailing: Icon(
          item.isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: Colors.white,
        ),
        onExpansionChanged: (newState) {
          setState(() => item.isExpanded = newState);
        },
        children: [_buildExpansionTileChildren(item)],
      ),
    );
  }

  Widget _buildSubtitle(AlarmItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(getFormattedScheduledDays(item.scheduledDays),
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        Switch(
          value: item.isEnabled,
          onChanged: (newValue) {
            setState(() => item.isEnabled = newValue);
          },
          activeColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildExpansionTileChildren(AlarmItem item) {
    const dayNames = ["S", "M", "T", "W", "T", "F", "S"];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [..._buildDaySelectors(item, dayNames)]),
          _buildSwitchRow(item.vibrationChecked, 'Vibration', (value) {
            setState(() => item.vibrationChecked = value!);
          }),
          _buildSwitchRow(item.syncWithMindr, 'Bind with Mindr', (value) {
            setState(() => item.syncWithMindr = value!);
          }),
        ],
      ),
    );
  }

  List<Widget> _buildDaySelectors(AlarmItem item, List<String> dayNames) {
    return List<Widget>.generate(7, (index) {
      bool isScheduled = item.scheduledDays.contains(index + 1);
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isScheduled) {
              item.scheduledDays.remove(index + 1);
            } else {
              item.scheduledDays.add(index + 1);
            }
          });
        },
        child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isScheduled
                ? const Color.fromARGB(255, 106, 200, 255)
                : const Color.fromARGB(255, 97, 97, 97),
            shape: BoxShape.circle,
          ),
          child: Text(
            dayNames[index],
            style: TextStyle(
              color: isScheduled
                  ? const Color.fromARGB(255, 44, 44, 44)
                  : const Color.fromARGB(255, 190, 190, 190),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSwitchRow(bool value, String text, Function(bool?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color.fromARGB(255, 106, 200, 255),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String getFormattedScheduledDays(List<int> scheduledDays) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<String> selectedDays = [];

    for (int dayIndex in scheduledDays) {
      if (dayIndex >= 1 && dayIndex <= 7) {
        selectedDays.add(dayNames[dayIndex - 1]);
      }
    }

    return selectedDays.join(', ');
  }
}
