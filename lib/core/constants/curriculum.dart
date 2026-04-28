import 'package:flutter/material.dart';

import 'package:studysync_syria/core/models/question.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';

/// Static curriculum data for the frontend-only version of StudySync Syria.
///
/// When the Supabase backend is added, this data will move server-side and
/// only be used as a fallback / seed.
class Curriculum {
  Curriculum._();

  static const Subject physics = Subject(
    id: 'physics',
    name: 'Physics',
    description: 'Mechanics, electricity, waves and modern physics.',
    icon: Icons.bolt_outlined,
    color: Color(0xFF2563EB),
  );

  static const Subject chemistry = Subject(
    id: 'chemistry',
    name: 'Chemistry',
    description: 'Atomic structure, bonding, organic and equilibrium.',
    icon: Icons.science_outlined,
    color: Color(0xFF059669),
  );

  static const List<Subject> subjects = <Subject>[physics, chemistry];

  static Subject? subjectById(String id) {
    for (final Subject s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// All topics across both subjects.
  static final List<Topic> topics = <Topic>[
    ..._physicsTopics,
    ..._chemistryTopics,
  ];

  static List<Topic> topicsForSubject(String subjectId) {
    return topics.where((Topic t) => t.subjectId == subjectId).toList();
  }

  static Topic? topicById(String id) {
    for (final Topic t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Physics
  // ---------------------------------------------------------------------------

  static final List<Topic> _physicsTopics = <Topic>[
    Topic(
      id: 'physics_mechanics',
      subjectId: 'physics',
      title: 'Mechanics',
      description: 'Kinematics, Newton\'s laws, work and energy.',
      lessonContent:
          'Mechanics studies the motion of objects and the forces acting on '
          'them. Key ideas include displacement, velocity and acceleration, '
          'Newton\'s three laws, and the work–energy theorem. For constant '
          'acceleration the kinematic equations apply, including v = u + at, '
          's = ut + ½at², and v² = u² + 2as.',
      questions: <Question>[
        Question(
          id: 'physics_mechanics_q1',
          prompt:
              'A body moves with constant acceleration. What equation relates '
              'final velocity, initial velocity, acceleration, and displacement?',
          options: <String>[
            'v² = u² + 2as',
            'F = ma',
            'P = IV',
            'E = mc²',
          ],
          correctOptionIndex: 0,
          workedSolution:
              'For constant acceleration without time, use v² = u² + 2as.',
        ),
        Question(
          id: 'physics_mechanics_q2',
          prompt:
              'A 2 kg object accelerates at 3 m/s². What net force acts on it?',
          options: <String>['1.5 N', '5 N', '6 N', '9 N'],
          correctOptionIndex: 2,
          workedSolution: 'Newton\'s 2nd law: F = ma = 2 × 3 = 6 N.',
        ),
      ],
    ),
    Topic(
      id: 'physics_electricity',
      subjectId: 'physics',
      title: 'Electricity',
      description: 'Circuits, Ohm\'s law and electric power.',
      lessonContent:
          'Electricity studies the flow of charge in conductors. Ohm\'s law '
          'states V = IR. Electric power is P = IV. In a series circuit the '
          'current is the same through every component, while in a parallel '
          'circuit the voltage across each branch is the same.',
      questions: <Question>[
        Question(
          id: 'physics_electricity_q1',
          prompt:
              'A 12 V battery drives 2 A through a resistor. What is its '
              'resistance?',
          options: <String>['3 Ω', '6 Ω', '14 Ω', '24 Ω'],
          correctOptionIndex: 1,
          workedSolution: 'Ohm\'s law: R = V / I = 12 / 2 = 6 Ω.',
        ),
        Question(
          id: 'physics_electricity_q2',
          prompt:
              'Which formula gives electric power in a simple resistive '
              'circuit?',
          options: <String>['P = IV', 'P = IR', 'P = V/I', 'P = I/V'],
          correctOptionIndex: 0,
          workedSolution: 'Electrical power dissipated is P = IV.',
        ),
      ],
    ),
    Topic(
      id: 'physics_waves',
      subjectId: 'physics',
      title: 'Waves',
      description: 'Wave properties, sound, and the wave equation.',
      lessonContent:
          'Waves transfer energy without transferring matter. The wave '
          'equation relates speed, frequency and wavelength: v = fλ. Waves '
          'can be transverse (e.g. light) or longitudinal (e.g. sound), and '
          'exhibit reflection, refraction, diffraction and interference.',
      questions: <Question>[
        Question(
          id: 'physics_waves_q1',
          prompt:
              'A wave has frequency 50 Hz and wavelength 4 m. What is its '
              'speed?',
          options: <String>['12.5 m/s', '54 m/s', '200 m/s', '46 m/s'],
          correctOptionIndex: 2,
          workedSolution: 'v = fλ = 50 × 4 = 200 m/s.',
        ),
      ],
    ),
    Topic(
      id: 'physics_modern',
      subjectId: 'physics',
      title: 'Modern Physics',
      description: 'Photons, the photoelectric effect and atomic models.',
      lessonContent:
          'Modern physics introduces quantum ideas. The energy of a photon is '
          'E = hf, where h is Planck\'s constant. The photoelectric effect '
          'shows that light behaves as discrete packets (photons) and that '
          'electrons are emitted only when photon energy exceeds the work '
          'function of the metal.',
      questions: <Question>[
        Question(
          id: 'physics_modern_q1',
          prompt: 'Which equation gives the energy of a single photon?',
          options: <String>['E = mc²', 'E = hf', 'E = ½mv²', 'E = qV'],
          correctOptionIndex: 1,
          workedSolution: 'Photon energy is E = hf (Planck–Einstein relation).',
        ),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Chemistry
  // ---------------------------------------------------------------------------

  static final List<Topic> _chemistryTopics = <Topic>[
    Topic(
      id: 'chemistry_atomic_structure',
      subjectId: 'chemistry',
      title: 'Atomic Structure',
      description: 'Protons, neutrons, electrons and energy levels.',
      lessonContent:
          'Atoms are made of a small dense nucleus (protons and neutrons) '
          'surrounded by electrons in energy levels. The atomic number is the '
          'number of protons; the mass number is protons plus neutrons. '
          'Electrons fill shells starting from the lowest energy level.',
      questions: <Question>[
        Question(
          id: 'chemistry_atomic_q1',
          prompt: 'What does the atomic number of an element represent?',
          options: <String>[
            'Number of neutrons',
            'Number of protons',
            'Number of nucleons',
            'Number of electrons in the outer shell',
          ],
          correctOptionIndex: 1,
          workedSolution:
              'The atomic number Z is defined as the number of protons in '
              'the nucleus.',
        ),
      ],
    ),
    Topic(
      id: 'chemistry_bonding',
      subjectId: 'chemistry',
      title: 'Chemical Bonding',
      description: 'Ionic, covalent and metallic bonding.',
      lessonContent:
          'Atoms bond to reach a stable electron configuration. Ionic bonds '
          'form by electron transfer between metals and non-metals. Covalent '
          'bonds form by electron sharing between non-metals. Metallic bonds '
          'involve a lattice of positive ions in a sea of delocalised '
          'electrons.',
      questions: <Question>[
        Question(
          id: 'chemistry_bonding_q1',
          prompt: 'Which type of bond involves the sharing of electron pairs?',
          options: <String>['Ionic', 'Covalent', 'Metallic', 'Hydrogen'],
          correctOptionIndex: 1,
          workedSolution:
              'Covalent bonds form when atoms share one or more pairs of '
              'electrons.',
        ),
      ],
    ),
    Topic(
      id: 'chemistry_organic',
      subjectId: 'chemistry',
      title: 'Organic Chemistry',
      description: 'Hydrocarbons and functional groups.',
      lessonContent:
          'Organic chemistry studies compounds of carbon. Alkanes are '
          'saturated hydrocarbons with general formula CₙH₂ₙ₊₂. Alkenes '
          'contain a C=C double bond, and alcohols contain the –OH group. '
          'Functional groups determine the chemistry of an organic molecule.',
      questions: <Question>[
        Question(
          id: 'chemistry_organic_q1',
          prompt: 'What is the general formula of an alkane?',
          options: <String>[
            'CₙH₂ₙ',
            'CₙH₂ₙ₊₂',
            'CₙH₂ₙ₋₂',
            'CₙH₂ₙ₊₁OH',
          ],
          correctOptionIndex: 1,
          workedSolution:
              'Alkanes are saturated hydrocarbons with general formula '
              'CₙH₂ₙ₊₂.',
        ),
      ],
    ),
    Topic(
      id: 'chemistry_equilibrium',
      subjectId: 'chemistry',
      title: 'Chemical Equilibrium',
      description: 'Reversible reactions and Le Chatelier\'s principle.',
      lessonContent:
          'Many reactions are reversible and reach a dynamic equilibrium '
          'where forward and reverse rates are equal. Le Chatelier\'s '
          'principle states that if a system at equilibrium is disturbed, it '
          'shifts to counteract the disturbance — for example, increasing '
          'pressure favours the side with fewer gas moles.',
      questions: <Question>[
        Question(
          id: 'chemistry_equilibrium_q1',
          prompt:
              'According to Le Chatelier\'s principle, increasing pressure '
              'on a gas-phase equilibrium shifts the position towards…',
          options: <String>[
            'The side with more moles of gas',
            'The side with fewer moles of gas',
            'It does not shift',
            'The side that absorbs heat',
          ],
          correctOptionIndex: 1,
          workedSolution:
              'Higher pressure favours the side with fewer gas moles to '
              'reduce the disturbance.',
        ),
      ],
    ),
  ];
}
