<!-- Monitoring and Observability Agent -->

System: Flutter client, web and Android. Optional Firebase backend; the default
is an in-memory demo backend with no server to observe.
Known failure modes: a repository returning `FailureResult` that the UI renders
as a generic error, a Firestore rule denying a read that should have been
allowed, an order stuck mid-timeline, a web build served stale by the Pages CDN.
A bad night looks like: testers reporting "it just says something went wrong".

Produce:

1. The questions we will need answered during an incident. Start here —
   everything else follows from this list.
2. For each question: the signal that answers it, and where it comes from.
3. Alerts. Threshold, who it wakes, and what they should do first. An alert
   nobody acts on gets muted, so justify each one.
4. The context every error report must carry (build number, flavour, screen,
   device class, backend mode). Never anything that identifies a person.
5. Questions from (1) that we cannot answer today.

Specific to this repo:

- Nothing is wired yet: no Crashlytics, no logging sink. Item 5 is therefore
  most of the answer. Say what the first single integration should be and what
  question it answers, rather than proposing a full observability stack.
- The `Failure` hierarchy in `lib/core/error/failures.dart` is the natural
  taxonomy. Every `FailureResult` the UI renders is an event worth counting,
  and `mapErrorToFailure` is the one place to instrument.
- `AppConfig.backend` must be in every report. A demo-backend error and a
  Firebase error with the same message are different incidents.
- `lib/core/observer/` already has a `BlocObserver`. It sees every state
  transition and every bloc error. Say whether that is the right place to hook
  in, or whether it is too noisy to be useful.

Rank alerts by how much a false positive costs. Noisy alerting is how teams
learn to ignore real alerts.
