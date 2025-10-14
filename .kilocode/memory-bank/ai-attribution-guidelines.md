# AI Attribution Guidelines

## Purpose

This document establishes standards for documenting AI-assisted development contributions in the Crashwalk project. It ensures transparency, accountability, and compliance with emerging industry best practices for AI code attribution.

## Core Principles

### Transparency
- Clearly distinguish between human-authored and AI-assisted code
- Document specific AI tools and models used
- Include timeframes and versions of AI assistance
- Maintain detailed records of AI contributions

### Human Accountability
- Emphasize human direction, review, and integration of AI-generated code
- Document human validation processes
- Highlight human responsibility for final code quality and safety
- Record human decision-making in AI-assisted development

### Compliance
- Follow Linux Foundation guidelines for AI-generated code
- Align with Open Source Initiative (OSI) best practices
- Meet academic standards for AI collaboration transparency
- Stay current with evolving industry standards

## Documentation Standards

### README.md Attribution Format

When updating the Authors section in README.md:

```markdown
## Authors and Contributors

### Human Developer
- **[Name]** - [Role description]
  - [Specific human responsibilities]
  - [Human validation processes]

### AI-Assisted Development

[Brief overview statement]

#### AI Tools and Models Used

**[Tool Name with Model (Provider)]**
- **Role**: [High-level/low-level task description]
- **Contributions**:
  - [Specific contribution 1]
  - [Specific contribution 2]
- **Timeframe**: [YYYY-YYYY or YYYY-MM-DD]

#### Nature of AI Assistance

[Description of how AI was used and human oversight]

#### Attribution Standards

[Reference to industry standards followed]
```

### CONTRIBUTORS.md Update Process

#### Adding New AI Contributions

1. **Update Human Contributors Section**: Add or update human developer information
2. **Document AI Tools**: Add new AI tools to the AI Tools and Models section
3. **Component-Level Attribution**: Add entries to "AI Contribution by Component" section
4. **Version History**: Update the version history table with new entries

#### Template for Component Attribution

```
#### [Component Name] (`path/to/component`)
- **AI Tool**: [Tool Name with Model]
- **Contribution**: [Specific what AI did]
- **Human Review**: [What human validation occurred]
```

#### Version History Template

```
| [Version] | [Date] | [AI Tools Used] | [Key Changes] | [Human Validation] |
```

### Memory Bank Updates

#### When to Update Memory Bank

- When introducing new AI tools or models
- When AI contribution patterns change significantly
- When industry standards for AI attribution evolve
- When project undergoes major AI-assisted development phases

#### Memory Bank File Structure

- `ai-attribution-guidelines.md`: This current file with standards
- Update `context.md`: Note significant AI tool changes
- Update `tech.md`: Document new AI tools in technology stack

## AI Tool Documentation Requirements

### Required Information for Each AI Tool

1. **Tool Name and Provider**: e.g., "Kilocode with Claude 3.5 Sonnet (Anthropic)"
2. **Model Version**: Specific model version used
3. **Primary Role**: High-level vs. low-level tasks
4. **Contribution Scope**: What specific tasks the AI performed
5. **Timeframe**: When the AI tool was used
6. **Human Integration**: How human developers directed and reviewed the AI work

### AI Contribution Categories

#### High-Level Tasks (Strategic)
- Architecture design
- System planning
- Documentation authoring
- Workflow coordination
- Requirements analysis

#### Low-Level Tasks (Implementation)
- Code generation
- Unit test writing
- Debugging assistance
- Code optimization
- Documentation refinement

## Quality Assurance for AI-Generated Code

### Human Review Requirements

1. **Code Review**: All AI-generated code must be reviewed by human developers
2. **Safety Validation**: Critical safety logic must be human-verified
3. **Integration Testing**: AI code must pass comprehensive tests
4. **Documentation Review**: AI-generated documentation must be human-validated

### Testing Standards

- Unit tests for AI-generated components
- Integration tests for AI-assisted features
- Manual testing for critical functionality
- Regression testing for modified AI code

## Future Development Guidelines

### For New Contributors

1. **Read This Document**: Understand attribution requirements before using AI tools
2. **Document as You Go**: Record AI usage during development, not retrospectively
3. **Follow Templates**: Use provided templates for consistent documentation
4. **Maintain Transparency**: Be clear about what AI contributed vs. human work

### For Project Maintainers

1. **Regular Updates**: Review and update attribution documentation quarterly
2. **Standards Monitoring**: Stay current with evolving AI attribution standards
3. **Template Maintenance**: Update templates as standards evolve
4. **Training**: Ensure all contributors understand attribution requirements

## Industry Standards Reference

### Linux Foundation AI Guidelines
- Transparency in AI-generated code contributions
- Clear attribution of AI assistance
- Human accountability for AI-assisted work

### OSI Best Practices
- Distinction between human and AI authorship
- Full disclosure of development methodologies
- Compliance with open source principles

### Academic Standards
- Proper citation of AI tools and models
- Documentation of human-AI collaboration
- Ethical considerations in AI-assisted research

## Implementation Checklist

### For Each AI-Assisted Development Session

- [ ] Document AI tool and model used
- [ ] Record specific contributions
- [ ] Note human review process
- [ ] Update version history
- [ ] Validate through testing
- [ ] Update documentation

### Quarterly Review

- [ ] Audit attribution documentation
- [ ] Check compliance with current standards
- [ ] Update templates if needed
- [ ] Train new contributors

## Contact and Maintenance

**Maintainer**: Asa Kirby
**Last Updated**: 2025-10-08
**Review Schedule**: Quarterly

For questions about AI attribution or updates to these guidelines, contact the project maintainer.

---

*These guidelines ensure the Crashwalk project maintains transparency and accountability in AI-assisted development while following industry best practices.*