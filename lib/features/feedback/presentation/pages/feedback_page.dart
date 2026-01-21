import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/sliver_page_header.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const String _supportEmail = 'support@waterit.app';

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _deviceController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _emailController.dispose();
    _detailsController.dispose();
    _stepsController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = AppLayout.pagePadding(width);
          final contentMax = AppLayout.maxContentWidth(width);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverPageHeader(
                      title: 'Feedback',
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        spacing.sm,
                        padding.right,
                        padding.bottom,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report a bug',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(height: spacing.xs),
                            Text(
                              'Share what happened and we will look into it.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            SizedBox(height: spacing.lg),
                            _FeedbackField(
                              label: 'Subject',
                              controller: _subjectController,
                              hintText: 'Short summary',
                            ),
                            SizedBox(height: spacing.sm),
                            _FeedbackField(
                              label: 'Your email (optional)',
                              controller: _emailController,
                              hintText: 'name@email.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: spacing.sm),
                            _FeedbackField(
                              label: 'Details',
                              controller: _detailsController,
                              hintText: 'What went wrong?',
                              maxLines: 5,
                            ),
                            SizedBox(height: spacing.sm),
                            _FeedbackField(
                              label: 'Steps to reproduce (optional)',
                              controller: _stepsController,
                              hintText: '1) ... 2) ...',
                              maxLines: 4,
                            ),
                            SizedBox(height: spacing.sm),
                            _FeedbackField(
                              label: 'Device info (optional)',
                              controller: _deviceController,
                              hintText: 'Android 16, Pixel 8 Pro',
                            ),
                            SizedBox(height: spacing.lg),
                            AppPrimaryButton(
                              onPressed: _sendFeedback,
                              label: 'Send',
                            ),
                            SizedBox(height: spacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final subject = _subjectController.text.trim();
    final details = _detailsController.text.trim();
    if (subject.isEmpty || details.isEmpty) {
      _showError('Please add a subject and details.');
      return;
    }

    final email = _emailController.text.trim();
    final steps = _stepsController.text.trim();
    final device = _deviceController.text.trim();
    final body = StringBuffer()
      ..writeln('Bug report')
      ..writeln('Subject: $subject');
    if (email.isNotEmpty) {
      body.writeln('Contact: $email');
    }
    body
      ..writeln('')
      ..writeln('Details:')
      ..writeln(details);
    if (steps.isNotEmpty) {
      body
        ..writeln('')
        ..writeln('Steps:')
        ..writeln(steps);
    }
    if (device.isNotEmpty) {
      body
        ..writeln('')
        ..writeln('Device:')
        ..writeln(device);
    }

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: <String, String>{
        'subject': subject,
        'body': body.toString(),
      },
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showError('Unable to open email app.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _FeedbackField extends StatelessWidget {
  const _FeedbackField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
